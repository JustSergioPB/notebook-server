defmodule NotebookServer.PKIs do
  @moduledoc """
  The PKIs context.
  """
  import Ecto.Query, warn: false
  alias NotebookServer.PKIs.OrgCertificate
  alias NotebookServer.Repo

  alias NotebookServer.PKIs.UserCertificate
  alias NotebookServer.Orgs
  alias NotebookServer.Accounts

  @root_ca_subject "/CN=Root CA"
  @org_ca_subject "/CN=Stachelabs CA"
  @user_cert_subject "/CN=User Certificate"

  def create_root_ca do
    root_key = X509.PrivateKey.new_rsa(4096)
    root_cert = X509.Certificate.self_signed(root_key, @root_ca_subject, template: :root_ca)
    max_age = expiration_date(20)

    encrypted_root_key =
      Plug.Crypto.encrypt(secret(), to_string(:pki), root_key, max_age: max_age)

    File.mkdir_p!("./root")
    File.write!("./root/key.bin", encrypted_root_key)

    %OrgCertificate{}
    |> OrgCertificate.changeset(%{
      cert_pem: root_cert |> X509.Certificate.to_pem(),
      public_key_pem: root_key |> X509.PublicKey.derive() |> X509.PublicKey.to_pem(),
      level: :root,
      platform: :web2,
      expiration_date: max_age
    })
    |> Repo.insert()
  end

  def create_org_certificate(org_id) do
    org = Orgs.get_org!(org_id)
    root_org_cert = get_active_root_certificate()
    encrypted_root_key = File.read!("./root/key.bin")
    {:ok, root_key} = Plug.Crypto.decrypt(secret(), to_string(:pki), encrypted_root_key)

    org_key = X509.PrivateKey.new_rsa(4096)
    org_public_key = org_key |> X509.PublicKey.derive()
    max_age = expiration_date(10)

    org_cert =
      X509.Certificate.new(
        org_public_key,
        @org_ca_subject <> "/O=#{org.name}",
        root_org_cert.cert,
        root_key,
        template: :intermediate_ca
      )

    encrypted_org_key =
      Plug.Crypto.encrypt(secret(), to_string(:pki), org_key, max_age: max_age)

    File.mkdir_p!("./#{org.id}/certificates")
    File.write!("./#{org.id}/certificates/key.bin", encrypted_org_key)

    %OrgCertificate{}
    |> OrgCertificate.changeset(%{
      cert_pem: org_cert |> X509.Certificate.to_pem(),
      public_key_pem: org_public_key |> X509.PublicKey.to_pem(),
      level: :org,
      platform: :web2,
      expiration_date: max_age
    })
    |> Repo.insert()
  end

  def create_user_certificate(user_id) do
    user = Accounts.get_user!(user_id)
    org = Orgs.get_org!(user.org_id)
    org_cert = get_active_org_certificate(user.org_id)
    encrypted_org_key = File.read!("./#{user.org_id}/certificates/key.bin")
    {:ok, org_key} = Plug.Crypto.decrypt(secret(), to_string(:pki), encrypted_org_key)

    user_key = X509.PrivateKey.new_rsa(4096)
    user_public_key = user_key |> X509.PublicKey.derive()

    user_cert =
      X509.Certificate.new(
        user_public_key,
        @user_cert_subject <> "/CN=#{user.email}/O=#{org.name}",
        org_cert.cert,
        org_key,
        template: :server
      )

    encrypted_user_key =
      Plug.Crypto.encrypt(secret(), to_string(:pki), user_key, max_age: expiration_date())

    File.mkdir_p!("./#{user.org_id}/certificates")
    File.write!("./#{user.org_id}/certificates/#{user.id}.bin", encrypted_user_key)

    %UserCertificate{}
    |> UserCertificate.changeset(%{
      cert_pem: user_cert |> X509.Certificate.to_pem(),
      public_key_pem: user_public_key |> X509.PublicKey.to_pem(),
      user_id: user.id,
      org_id: user.org_id,
      expiration_date: expiration_date()
    })
    |> Repo.insert()
  end

  def list_org_certificates(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)
    level = Keyword.get(opts, :level) || :intermediate

    query =
      if(org_id) do
        from(p in OrgCertificate, where: p.org_id == ^org_id and p.level == ^level)
      else
        from(p in OrgCertificate, where: p.level == ^level)
      end

    query |> order_by(desc: :inserted_at) |> Repo.all()
  end

  def list_user_certificates(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if(org_id) do
        from(p in UserCertificate, where: p.org_id == ^org_id)
      else
        from(p in UserCertificate)
      end

    query = query |> order_by(asc: :inserted_at, asc: :user_id, desc: :status)

    Repo.all(query) |> Repo.preload(:org) |> Repo.preload(:user)
  end

  def get_org_certificate!(id), do: Repo.get!(OrgCertificate, id)

  def get_active_org_certificate(org_id) do
    from(p in OrgCertificate, where: p.org_id == ^org_id and p.status == :active)
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_active_root_certificate do
    from(p in OrgCertificate, where: p.level == :root and p.status == :active)
    |> order_by(desc: :inserted_at)
    |> limit(1)
    |> Repo.one()
  end

  def get_user_certificate!(id), do: Repo.get!(UserCertificate, id) |> Repo.preload(:user)

  defp expiration_date(years \\ 1) do
    DateTime.utc_now() |> DateTime.add(years * 365 * 24 * 60 * 60, :second)
  end

  defp secret() do
    Application.get_env(:notebook_server, NotebookServer.PKIs)[:pki_secret_key]
  end
end

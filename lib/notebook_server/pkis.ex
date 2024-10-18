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
  @root_path "./root"
  @intermediate_path "/intermediate"
  @user_path "/user"
  @private_key_path "/private-key.bin"
  @public_key_path "/public-key.pem"
  @cert_path "/cert.pem"
  @aes_block_size 16
  @salt_size 16
  @iterations 100_000
  # AES-256
  @key_size 32

  def create_root_certificate do
    root_org = Orgs.get_root_org!()
    max_age = expiration_date(20)

    credentials = generate_root_credentials()
    store_root_credentials(credentials.private_key, credentials.public_key, credentials.cert)

    %OrgCertificate{}
    |> OrgCertificate.changeset(%{
      level: :root,
      expiration_date: max_age,
      org_id: root_org.id
    })
    |> Repo.insert()
  end

  def create_org_certificate(org_name) do
    org = Orgs.get_org_by_name(org_name)
    max_age = expiration_date(10)
    root_credentials = retrieve_root_credentials()

    org_credentials =
      generate_org_credentials(org.name, root_credentials.private_key, root_credentials.cert)

    store_org_credentials(
      org.id,
      org_credentials.private_key,
      org_credentials.public_key,
      org_credentials.cert
    )

    %OrgCertificate{}
    |> OrgCertificate.changeset(%{
      expiration_date: max_age,
      org_id: org.id
    })
    |> Repo.insert()
  end

  def create_user_certificate(user_email) do
    user = Accounts.get_user_by_email_with_org(user_email)
    IO.inspect(user)
    org_credentials = retrieve_org_credentials(user.org.id)

    user_credentials =
      generate_user_credentials(
        user.org.name,
        user.email,
        org_credentials.private_key,
        org_credentials.cert
      )

    store_user_credentials(
      user.org.id,
      user.id,
      user_credentials.private_key,
      user_credentials.public_key,
      user_credentials.cert
    )

    %UserCertificate{}
    |> UserCertificate.changeset(%{
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

    query |> order_by(desc: :inserted_at) |> Repo.all() |> Repo.preload(:org)
  end

  def list_user_certificates(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if(org_id) do
        from(p in UserCertificate, where: p.org_id == ^org_id)
      else
        from(p in UserCertificate)
      end

    query
    |> order_by(asc: :inserted_at, asc: :user_id, desc: :status)
    |> Repo.all()
    |> Repo.preload(:org)
    |> Repo.preload(:user)
  end

  def get_org_certificate!(id), do: Repo.get!(OrgCertificate, id)

  def get_user_certificate!(id), do: Repo.get!(UserCertificate, id) |> Repo.preload(:user)

  defp generate_root_credentials do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive()
    cert = X509.Certificate.self_signed(private_key, @root_ca_subject, template: :root_ca)

    %{
      :private_key => private_key |> X509.PrivateKey.to_pem(),
      :public_key => public_key |> X509.PublicKey.to_pem(),
      :cert => cert |> X509.Certificate.to_pem()
    }
  end

  defp generate_org_credentials(org_name, root_private_key, root_cert) do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive()

    cert =
      X509.Certificate.new(
        public_key,
        @org_ca_subject <> "/O=#{org_name}",
        root_cert,
        root_private_key,
        template: :ca
      )

    %{
      :private_key => private_key |> X509.PrivateKey.to_pem(),
      :public_key => public_key |> X509.PublicKey.to_pem(),
      :cert => cert |> X509.Certificate.to_pem()
    }
  end

  defp generate_user_credentials(org_name, user_email, org_private_key, org_cert) do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive()

    cert =
      X509.Certificate.new(
        public_key,
        @user_cert_subject <> "/CN=#{user_email}/O=#{org_name}",
        org_cert,
        org_private_key,
        template: :server
      )

    %{
      :private_key => private_key |> X509.PrivateKey.to_pem(),
      :public_key => public_key |> X509.PublicKey.to_pem(),
      :cert => cert |> X509.Certificate.to_pem()
    }
  end

  defp store_root_credentials(private_key, public_key, cert) do
    File.mkdir_p!(@root_path)
    File.write!(@root_path <> @private_key_path, encrypt_private_key(private_key))

    File.write!(
      @root_path <> @public_key_path,
      public_key
    )

    File.write!(@root_path <> @cert_path, cert)
  end

  defp store_org_credentials(org_id, private_key, public_key, cert) do
    File.mkdir_p!("./#{org_id}#{@intermediate_path}")

    File.write!(
      "./#{org_id}#{@intermediate_path}#{@private_key_path}",
      encrypt_private_key(private_key)
    )

    File.write(
      "./#{org_id}#{@intermediate_path}#{@public_key_path}",
      public_key
    )

    File.write(
      "./#{org_id}#{@intermediate_path}#{@cert_path}",
      cert
    )
  end

  defp store_user_credentials(org_id, user_id, private_key, public_key, cert) do
    File.mkdir_p!("./#{org_id}#{@user_path}")
    File.mkdir_p!("./#{org_id}#{@user_path}/#{user_id}")

    File.write!(
      "./#{org_id}#{@user_path}/#{user_id}#{@private_key_path}",
      encrypt_private_key(private_key)
    )

    File.write!(
      "./#{org_id}#{@user_path}/#{user_id}#{@public_key_path}",
      public_key
    )

    File.write!(
      "./#{org_id}#{@user_path}/#{user_id}#{@cert_path}",
      cert
    )
  end

  defp retrieve_root_credentials do
    public_key = File.read!(@root_path <> @public_key_path)

    {:ok, private_key} =
      decrypt_private_key(@root_path <> @private_key_path)

    cert = File.read!(@root_path <> @cert_path)

    %{
      :public_key => public_key |> X509.PublicKey.from_pem!(),
      :private_key => private_key |> X509.PrivateKey.from_pem!(),
      :cert => cert |> X509.Certificate.from_pem!()
    }
  end

  defp retrieve_org_credentials(org_id) do
    public_key = File.read!("./#{org_id}" <> @intermediate_path <> @public_key_path)

    {:ok, private_key} =
      decrypt_private_key("./#{org_id}" <> @intermediate_path <> @private_key_path)

    cert = File.read!("./#{org_id}" <> @intermediate_path <> @cert_path)

    %{
      :public_key => public_key |> X509.PublicKey.from_pem!(),
      :private_key => private_key |> X509.PrivateKey.from_pem!(),
      :cert => cert |> X509.Certificate.from_pem!()
    }
  end

  defp encrypt_private_key(private_key_pem) when is_binary(private_key_pem) do
    salt = :crypto.strong_rand_bytes(@salt_size)
    iv = :crypto.strong_rand_bytes(@aes_block_size)
    key = derive_key(secret(), salt)
    padding_size = @aes_block_size - rem(byte_size(private_key_pem), @aes_block_size)
    padding = String.duplicate(<<padding_size>>, padding_size)
    encrypted = :crypto.crypto_one_time(:aes_256_cbc, key, iv, private_key_pem <> padding, true)
    salt <> iv <> encrypted
  end

  defp decrypt_private_key(file_path) do
    file_content = File.read!(file_path)

    <<salt::binary-size(@salt_size), iv::binary-size(@aes_block_size), encrypted::binary>> =
      file_content

    key = derive_key(secret(), salt)
    decrypt(encrypted, key, iv)
  end

  defp derive_key(password, salt) do
    :crypto.pbkdf2_hmac(:sha256, password, salt, @iterations, @key_size)
  end

  defp decrypt(ciphertext, key, iv) do
    case :crypto.crypto_one_time(:aes_256_cbc, key, iv, ciphertext, false) do
      decrypted when is_binary(decrypted) ->
        padding_size = :binary.last(decrypted)
        unpadded = binary_part(decrypted, 0, byte_size(decrypted) - padding_size)
        {:ok, unpadded}
    end
  end

  defp expiration_date(years \\ 1) do
    DateTime.utc_now() |> DateTime.add(years * 365 * 24 * 60 * 60, :second)
  end

  defp secret() do
    Application.get_env(:notebook_server, NotebookServer.PKIs)[:pki_secret_key]
  end
end

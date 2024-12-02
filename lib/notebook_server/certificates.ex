defmodule NotebookServer.Certificates do
  alias NotebookServer.Repo
  alias NotebookServer.Certificates.Certificate
  alias NotebookServer.Certificates.OrgCertificate
  alias NotebookServer.Certificates.UserCertificate
  alias NotebookServer.Orgs.Org
  alias NotebookServer.Accounts.User
  import Ecto.Query, warn: false

  # TODO: limit creation when there's already an active certificate
  def create_certificate(term, attrs \\ %{})

  def create_certificate(:org, attrs) do
    private_key_pem = attrs |> get_in(["certificate", "private_key_pem"])
    public_id = attrs |> get_in(["certificate", "public_id"])

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_certificate, OrgCertificate.changeset(%OrgCertificate{}, attrs))
    |> Ecto.Multi.run(:store_private_key, fn _, _ ->
      File.mkdir_p!("./priv/static/pk/")

      File.write(private_key_path(public_id), private_key_pem)
      |> case do
        :ok -> {:ok, nil}
        {:error, error} -> {:error, error}
      end
    end)
    |> Repo.transaction()
  end

  def create_certificate(:user, attrs) do
    private_key_pem = attrs |> get_in(["certificate", "private_key_pem"])
    public_id = attrs |> get_in(["certificate", "public_id"])

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :create_certificate,
      UserCertificate.changeset(%UserCertificate{}, attrs)
    )
    |> Ecto.Multi.run(:store_private_key, fn _, _ ->
      File.mkdir_p!("./priv/static/pk/")

      File.write(private_key_path(public_id), private_key_pem)
      |> case do
        :ok -> {:ok, nil}
        {:error, error} -> {:error, error}
      end
    end)
    |> Repo.transaction()
  end

  def get_issuer_certificate!(org_id, level) do
    certificate =
      Repo.one!(
        from(c in Certificate,
          left_join: oc in OrgCertificate,
          on: c.id == oc.certificate_id,
          where: oc.org_id == ^org_id and c.status == :active and c.level == ^level
        )
      )

    private_key = File.read!(private_key_path(certificate.public_id))

    certificate
    |> Map.put(:private_key_pem, private_key |> X509.PrivateKey.from_pem!(password: pki_secret()))
  end

  def list_certificates(:org) do
    Repo.all(OrgCertificate) |> Repo.preload([:org, :certificate])
  end

  def list_certificates(:user) do
    Repo.all(UserCertificate)
    |> Repo.preload([:org, :user, :certificate])
  end

  def get_certificate!(:org, id),
    do: Repo.get!(OrgCertificate, id) |> Repo.preload([:org, :certificate])

  def get_certificate!(:user, id),
    do: Repo.get!(UserCertificate, id) |> Repo.preload([:org, :user, :certificate])

  def rotate_certificate(
        :org,
        %OrgCertificate{} = rotated,
        replacement
      ) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :rotate_certificate,
      Certificate.rotate_changeset(rotated.certificate)
    )
    |> Ecto.Multi.run(
      :create_replacement,
      create_certificate(:org, replacement)
    )
    |> Repo.transaction()
  end

  def rotate_certificate(:user, %UserCertificate{} = rotated, replacement) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :rotate_certificate,
      Certificate.rotate_changeset(rotated.certificate)
    )
    |> Ecto.Multi.run(
      :create_replacement,
      create_certificate(:user, replacement)
    )
    |> Repo.transaction()
  end

  def revoke_certificate(:org, %OrgCertificate{} = org_certificate, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :revoke_certificate,
      Certificate.revoke_changeset(org_certificate.certificate, attrs)
    )
    |> Ecto.Multi.update_all(
      # TODO: make it recursive
      :revoke_related_certificates,
      fn %{revoke_org_certificate: revoked} ->
        from(c in Certificate,
          where: c.issued_by_id == ^revoked.certificate_id,
          update: [
            set: [
              status: :revoked
            ]
          ]
        )
      end,
      []
    )
    |> Repo.transaction()
  end

  def revoke_certificate(:user, %UserCertificate{} = user_certificate, attrs) do
    user_certificate.certificate |> Certificate.revoke_changeset(attrs) |> Repo.update()
  end

  def delete_certificate(:user, %UserCertificate{} = user_certificate) do
    Repo.delete(user_certificate.certificate)
  end

  def delete_certificate(:org, %OrgCertificate{} = org_certificate) do
    Repo.delete(org_certificate.certificate)
  end

  def change_certificate(term, certificate, attrs \\ %{})

  def change_certificate(:user, user_certificate, attrs) do
    user_certificate
    |> UserCertificate.changeset(attrs)
  end

  def change_certificate(:org, org_certificate, attrs) do
    org_certificate
    |> OrgCertificate.changeset(attrs)
  end

  def complete_certificate(:org, %Org{} = org, level) do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive()
    certificate_content = gen_certification_content(level, org)
    issuer_level = gen_issuer_level(level)
    cert_template = gen_cert_template(level)
    issuer = if level != :root, do: get_issuer_certificate!(org.id, issuer_level)

    cert =
      if level != :root,
        do:
          X509.Certificate.new(
            public_key,
            certificate_content,
            issuer.cert_pem |> X509.Certificate.from_pem!(),
            issuer.private_key_pem,
            template: cert_template
          ),
        else:
          X509.Certificate.self_signed(private_key, certificate_content, template: cert_template)

    %{
      "org_id" => org.id,
      "certificate" => %{
        "level" => level,
        "public_key_pem" => public_key |> X509.PublicKey.to_pem(),
        "cert_pem" => cert |> X509.Certificate.to_pem(),
        "private_key_pem" => private_key |> X509.PrivateKey.to_pem(password: pki_secret()),
        "expiration_date" => gen_expiration_date(level),
        "public_id" => Ecto.UUID.generate()
      }
    }
  end

  def complete_certificate(:user, %Org{} = org, %User{} = user) do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive()

    issuer = get_issuer_certificate!(org.id, :intermediate)

    cert =
      X509.Certificate.new(
        public_key,
        "/CN=Entity Certificate/CN=#{user.email}/O=#{org.name}",
        issuer.cert_pem |> X509.Certificate.from_pem!(),
        issuer.private_key_pem,
        template: :server
      )

    %{
      "org_id" => org.id,
      "user_id" => user.id,
      "certificate" => %{
        "public_key_pem" => public_key |> X509.PublicKey.to_pem(),
        "cert_pem" => cert |> X509.Certificate.to_pem(),
        "private_key_pem" => private_key |> X509.PrivateKey.to_pem(password: pki_secret()),
        "expiration_date" => gen_expiration_date(:entity),
        "issued_by_id" => issuer.id,
        "public_id" => Ecto.UUID.generate()
      }
    }
  end

  defp gen_certification_content(:root, _), do: "/CN=Root CA"

  defp gen_certification_content(:intermediate, %Org{} = org), do: "/CN=CA CA/O=#{org.name}"

  defp gen_certification_content(:entity, %Org{} = org),
    do: "/CN=Server Certificate/CN=#{org.email}/O=#{org.name}"

  defp gen_issuer_level(:root), do: nil

  defp gen_issuer_level(:intermediate), do: :root

  defp gen_issuer_level(:entity), do: :intermediate

  defp gen_cert_template(:root), do: :root_ca

  defp gen_cert_template(:intermediate), do: :ca

  defp gen_cert_template(:entity), do: :server

  defp gen_expiration_date(:root),
    do: DateTime.utc_now() |> DateTime.add(25 * 365 * 24 * 60 * 60, :second)

  defp gen_expiration_date(:intermediate),
    do: DateTime.utc_now() |> DateTime.add(10 * 365 * 24 * 60 * 60, :second)

  defp gen_expiration_date(:entity),
    do: DateTime.utc_now() |> DateTime.add(365 * 24 * 60 * 60, :second)

  defp private_key_path(public_id) do
    "./priv/static/pk/#{public_id}.key"
  end

  defp pki_secret do
    Application.get_env(:notebook_server, NotebookServer.Certificates)[:pki_secret_key]
  end
end

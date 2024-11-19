defmodule NotebookServer.Certificates do
  alias NotebookServer.Repo
  alias NotebookServer.Certificates.Certificate
  alias NotebookServer.Certificates.OrgCertificate
  alias NotebookServer.Certificates.UserCertificate
  alias NotebookServer.Certificates.EncryptionTools
  alias NotebookServer.Orgs.Org
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext
  import Ecto.Query, warn: false

  # TODO: limit creation when there's already an active certificate
  def create_certificate(term, attrs \\ %{})

  def create_certificate(:org, attrs) do
    level = attrs |> Map.get("certificate") |> Map.get("level") |> String.to_atom()
    create_org_certificate(level, attrs)
  end

  def create_certificate(:user, attrs) do
    user_id = attrs |> Map.get("user_id")
    org_id = attrs |> Map.get("org_id")

    Ecto.Multi.new()
    |> Ecto.Multi.one(:find_user, from(u in User, where: u.id == ^user_id))
    |> Ecto.Multi.one(:find_org, from(o in Org, where: o.id == ^org_id))
    |> find_issuer_certificate(org_id, :intermediate)
    |> complete_user_certificate(attrs)
    |> Ecto.Multi.insert(
      :create_certificate,
      fn %{complete_certificate: certificate} ->
        UserCertificate.changeset(%UserCertificate{}, certificate)
      end
    )
    |> store_private_key()
    |> Repo.transaction()
    |> case do
      {:ok, %{create_certificate: certificate}} ->
        {:ok, certificate, dgettext("certificates", "certificate_creation_succeded")}

      {:error, :create_certificate, certificate, _} ->
        {:error, certificate, dgettext("certificates", "certificate_creation_failed")}

      {:error, :find_user, _, _} ->
        {:error, dgettext("users", "user_search_failed")}

      {:error, :find_org, _, _} ->
        {:error, dgettext("orgs", "org_search_failed")}

      {:error, :find_issuer_certificate, _, _} ->
        {:error, dgettext("certificates", "issuer_certificate_search_failed")}

      {:error, :check_issuer_certificate, _, _} ->
        {:error, dgettext("certificates", "issuer_certificate_check_failed")}

      {:error, :store_private_key, _, _} ->
        {:error, dgettext("certificates", "certificate_storage_failed")}
    end
  end

  def complete_user_certificate(multi, attrs) do
    multi
    |> Ecto.Multi.run(
      :complete_certificate,
      fn _,
         %{
           find_user: user,
           find_org: org,
           find_issuer_certificate: issuer_certificate,
           retrieve_encrypted_private_key: encrypted_private_key
         } ->
        certificate =
          attrs
          |> Map.get("certificate")
          |> complete_certificate(
            :entity,
            "/CN=Entity Certificate/CN=#{user.email}/O=#{org.name}",
            issuer_certificate,
            encrypted_private_key
          )

        {:ok, attrs |> Map.merge(%{"certificate" => certificate, "org_id" => user.org_id})}
      end
    )
  end

  defp create_org_certificate(:root, attrs) do
    Ecto.Multi.new()
    |> complete_org_certificate(attrs, :root)
    |> Ecto.Multi.insert(
      :create_certificate,
      fn %{complete_certificate: certificate} ->
        OrgCertificate.changeset(
          %OrgCertificate{},
          certificate
        )
      end
    )
    |> store_private_key()
    |> Repo.transaction()
    |> case do
      {:ok, %{create_certificate: certificate}} ->
        {:ok, certificate, dgettext("certificates", "certificate_creation_succeded")}

      {:error, :create_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_creation_failed")}

      {:error, :store_private_key, _, _} ->
        {:error, dgettext("certificates", "certificate_storage_failed")}
    end
  end

  defp create_org_certificate(:intermediate, attrs) do
    org_id = attrs |> Map.get("org_id")

    Ecto.Multi.new()
    |> Ecto.Multi.one(:find_org, from(o in Org, where: o.id == ^org_id))
    |> find_issuer_certificate(org_id, :root)
    |> complete_org_certificate(attrs, :intermediate)
    |> Ecto.Multi.insert(
      :create_certificate,
      fn %{complete_certificate: certificate} ->
        OrgCertificate.changeset(
          %OrgCertificate{},
          certificate
        )
      end
    )
    |> store_private_key()
    |> Repo.transaction()
    |> case do
      {:ok, %{create_certificate: certificate}} ->
        {:ok, certificate, dgettext("certificates", "certificate_creation_succeded")}

      {:error, :find_org, _, _} ->
        {:error, dgettext("orgs", "org_search_failed")}

      {:error, :find_issuer_certificate, _, _} ->
        {:error, dgettext("certificates", "issuer_certificate_search_failed")}

      {:error, :check_issuer_certificate, _, _} ->
        {:error, dgettext("certificates", "issuer_certificate_check_failed")}

      {:error, :create_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_creation_failed")}

      {:error, :store_private_key, _, _} ->
        {:error, dgettext("certificates", "certificate_storage_failed")}
    end
  end

  defp create_org_certificate(:entity, attrs) do
    org_id = attrs |> Map.get("org_id")

    Ecto.Multi.new()
    |> Ecto.Multi.one(:find_org, from(o in Org, where: o.id == ^org_id))
    |> find_issuer_certificate(org_id, :intermediate)
    |> complete_org_certificate(attrs, :entity)
    |> Ecto.Multi.insert(
      :create_certificate,
      fn %{complete_certificate: certificate} ->
        OrgCertificate.changeset(
          %OrgCertificate{},
          certificate
        )
      end
    )
    |> store_private_key()
    |> Repo.transaction()
    |> case do
      {:ok, %{create_certificate: certificate}} ->
        {:ok, certificate, dgettext("certificates", "certificate_creation_succeded")}

      {:error, :find_org, _, _} ->
        {:error, dgettext("orgs", "org_search_failed")}

      {:error, :find_issuer_certificate, _, _} ->
        {:error, dgettext("certificates", "issuer_certificate_search_failed")}

      {:error, :check_issuer_certificate, _, _} ->
        {:error, dgettext("certificates", "issuer_certificate_check_failed")}

      {:error, :create_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_creation_failed")}

      {:error, :store_private_key, _, _} ->
        {:error, dgettext("certificates", "certificate_storage_failed")}
    end
  end

  def complete_org_certificate(multi, attrs, :root) do
    multi
    |> Ecto.Multi.run(
      :complete_certificate,
      fn _, _ ->
        certificate =
          attrs
          |> Map.get("certificate")
          |> complete_certificate(:root)

        {:ok, attrs |> Map.put("certificate", certificate)}
      end
    )
  end

  def complete_org_certificate(multi, attrs, :intermediate) do
    multi
    |> Ecto.Multi.run(
      :complete_certificate,
      fn _,
         %{
           find_org: org,
           find_issuer_certificate: issuer_certificate,
           retrieve_encrypted_private_key: encrypted_private_key
         } ->
        certificate =
          attrs
          |> Map.get("certificate")
          |> complete_certificate(
            :intermediate,
            "/CN=Stachelabs CA/O=#{org.name}",
            issuer_certificate,
            encrypted_private_key
          )

        {:ok, attrs |> Map.put("certificate", certificate)}
      end
    )
  end

  def complete_org_certificate(multi, attrs, :entity) do
    multi
    |> Ecto.Multi.run(
      :complete_certificate,
      fn _,
         %{
           find_org: org,
           find_issuer_certificate: issuer_certificate,
           retrieve_encrypted_private_key: encrypted_private_key
         } ->
        certificate =
          attrs
          |> Map.get("certificate")
          |> complete_certificate(
            :entity,
            "/CN=Entity Certificate/CN=#{org.email}/O=#{org.name}",
            issuer_certificate,
            encrypted_private_key
          )

        {:ok, attrs |> Map.put("certificate", certificate)}
      end
    )
  end

  def complete_certificate(certificate, :root) do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive() |> X509.PublicKey.to_pem()
    encrypted = private_key |> X509.PrivateKey.to_pem() |> EncryptionTools.encrypt_private_key()

    cert =
      private_key
      |> X509.Certificate.self_signed("/CN=Root CA", template: :root_ca)
      |> X509.Certificate.to_pem()

    certificate
    |> Map.merge(%{
      "public_key_pem" => public_key,
      "cert_pem" => cert,
      "encrypted_private_key" => encrypted,
      "expiration_date" => gen_expiration_date(:root),
      "public_id" => Ecto.UUID.generate()
    })
  end

  def complete_certificate(certificate, level, content, issuer, encrypted_private_key)
      when level in [:intermediate, :entity] do
    private_key = X509.PrivateKey.new_rsa(4096)
    public_key = private_key |> X509.PublicKey.derive()
    encrypted = private_key |> X509.PrivateKey.to_pem() |> EncryptionTools.encrypt_private_key()

    issuer_cert =
      issuer |> Map.get(:cert_pem) |> X509.Certificate.from_pem!()

    {:ok, issuer_private_key} =
      encrypted_private_key
      |> EncryptionTools.decrypt_private_key()

    cert =
      X509.Certificate.new(
        public_key,
        content,
        issuer_cert,
        issuer_private_key |> X509.PrivateKey.from_pem!(),
        template: :server
      )

    certificate
    |> Map.merge(%{
      "public_key_pem" => public_key |> X509.PublicKey.to_pem(),
      "cert_pem" => cert |> X509.Certificate.to_pem(),
      "encrypted_private_key" => encrypted,
      "expiration_date" => gen_expiration_date(level),
      "issued_by_id" => issuer.id,
      "public_id" => Ecto.UUID.generate()
    })
  end

  defp gen_expiration_date(level) do
    years =
      case level do
        :root -> 25
        :intermediate -> 10
        :entity -> 1
      end

    DateTime.utc_now() |> DateTime.add(years * 365 * 24 * 60 * 60, :second)
  end

  defp store_private_key(multi) do
    multi
    |> Ecto.Multi.run(
      :store_private_key,
      fn _repo, %{create_certificate: certificate, complete_certificate: complete} ->
        File.mkdir_p!("./priv/static/pk")

        pk = complete |> get_in(["certificate", "encrypted_private_key"])

        File.write(
          "./priv/static/pk/#{certificate.certificate.public_id}.bin",
          pk
        )
        |> case do
          :ok -> {:ok, nil}
          {:error, value} -> {:error, value}
        end
      end
    )
  end

  defp find_issuer_certificate(multi, org_id, level) do
    multi
    |> Ecto.Multi.one(
      :find_issuer_certificate,
      from(c in Certificate,
        left_join: oc in OrgCertificate,
        on: c.id == oc.certificate_id,
        where: oc.org_id == ^org_id and c.status == :active and c.level == ^level
      )
    )
    |> Ecto.Multi.run(
      :check_issuer_certificate,
      fn _repo, %{find_issuer_certificate: certificate} ->
        if !is_nil(certificate), do: {:ok, nil}, else: {:error, nil}
      end
    )
    |> Ecto.Multi.run(
      :retrieve_encrypted_private_key,
      fn _repo, %{find_issuer_certificate: certificate} ->
        File.read("./priv/static/pk/#{certificate.public_id}.bin")
      end
    )
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

  def rotate_certificate(:org, org_certificate) do
    # TODO: check in future how to improve this
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :rotate_org_certificate,
      OrgCertificate.rotate_changeset(org_certificate)
    )
    |> Ecto.Multi.update_all(
      :rotate_certificate,
      fn %{rotate_org_certificate: org_certificate} ->
        from(c in Certificate,
          where: c.id == ^org_certificate.certificate_id,
          update: [
            set: [
              status: :rotated
            ]
          ]
        )
      end,
      []
    )
    |> Ecto.Multi.run(
      :create_replacement,
      fn _repo, %{rotate_org_certificate: org_certificate} ->
        # TODO, give a thought about using same platform
        new_certificate = %{
          "org_id" => org_certificate.org_id,
          "certificate" => %{
            "platform" => org_certificate.certificate.platform |> Atom.to_string(),
            "level" => org_certificate.certificate.level |> Atom.to_string(),
            "replaces_id" => org_certificate.certificate.id
          }
        }

        case create_certificate(:org, new_certificate) do
          {:ok, _, _} -> {:ok, nil}
          {:error, _, _} -> {:error, nil}
          {:error, _} -> {:error, nil}
        end
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{rotate_org_certificate: org_certificate}} ->
        {:ok, org_certificate, dgettext("certificates", "certificate_rotation_succeded")}

      {:error, :rotate_org_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_rotation_failed")}

      {:error, :rotate_certificate, _, _} ->
        {:error, dgettext("certificates", "certificate_rotation_failed")}

      {:error, :create_replacement, _, _} ->
        {:error, dgettext("certificates", "certificate_creation_failed")}
    end
  end

  def rotate_certificate(:user, user_certificate) do
    # TODO: check in future how to improve this
    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :rotate_user_certificate,
      UserCertificate.rotate_changeset(user_certificate)
    )
    |> Ecto.Multi.update_all(
      :rotate_certificate,
      fn %{rotate_user_certificate: user_certificate} ->
        from(c in Certificate,
          where: c.id == ^user_certificate.certificate_id,
          update: [
            set: [
              status: :rotated
            ]
          ]
        )
      end,
      []
    )
    |> Ecto.Multi.run(
      :create_replacement,
      fn _repo, %{rotate_user_certificate: user_certificate} ->
        new_certificate = %{
          "org_id" => user_certificate.org_id,
          "user_id" => user_certificate.org_id,
          "certificate" => %{
            "platform" => user_certificate.certificate.platform |> Atom.to_string(),
            "level" => user_certificate.certificate.level |> Atom.to_string(),
            "replaces_id" => user_certificate.certificate.id
          }
        }

        case create_certificate(:user, new_certificate) do
          {:ok, new_certificate, _} -> {:ok, new_certificate}
          {:error, _, _} -> {:error, nil}
          {:error, _} -> {:error, nil}
        end
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok,
       %{
         rotate_user_certificate: user_certificate,
         create_replacement: replacement
       }} ->
        {:ok, user_certificate, replacement,
         dgettext("certificates", "certificate_rotation_succeded")}

      {:error, :rotate_user_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_rotation_failed")}

      {:error, :rotate_certificate, _, _} ->
        {:error, dgettext("certificates", "certificate_rotation_failed")}

      {:error, :create_replacement, _, _} ->
        {:error, dgettext("certificates", "certificate_creation_failed")}
    end
  end

  def revoke_certificate(:org, org_certificate, attrs) do
    revocation_date = DateTime.utc_now()
    revocation_reason = attrs |> get_in(["certificate", "revocation_reason"])
    certificate = attrs |> Map.get("certificate") |> Map.put("revocation_date", revocation_date)
    attrs = attrs |> Map.put("certificate", certificate)

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :revoke_org_certificate,
      OrgCertificate.revoke_changeset(org_certificate, attrs)
    )
    |> Ecto.Multi.update_all(
      :revoke_certificate,
      fn %{revoke_org_certificate: org_certificate} ->
        from(c in Certificate,
          where: c.id == ^org_certificate.certificate_id,
          update: [
            set: [
              status: :revoked,
              revocation_date: ^revocation_date,
              revocation_reason: ^revocation_reason
            ]
          ]
        )
      end,
      []
    )
    |> Ecto.Multi.update_all(
      # TODO: make it recursive
      :revoke_related_certificates,
      fn %{revoke_org_certificate: revoked} ->
        from(c in Certificate,
          where: c.issued_by_id == ^revoked.certificate_id,
          update: [
            set: [
              status: :revoked,
              revocation_date: ^revocation_date,
              revocation_reason: ^revocation_reason
            ]
          ]
        )
      end,
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{revoke_org_certificate: revoked}} ->
        {:ok, revoked, dgettext("certificates", "certificate_revokation_succeded")}

      {:error, :revoke_org_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_revokation_failed")}

      {:error, :revoke_related_certificates, _, _} ->
        {:error, dgettext("certificates", "related_certificates_revokation_failed")}
    end
  end

  def revoke_certificate(:user, user_certificate, attrs) do
    revocation_date = DateTime.utc_now()
    revocation_reason = attrs |> Map.get(:revocation_reason)
    attrs = attrs |> Map.put(:revocation_date, revocation_date)

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :revoke_user_certificate,
      OrgCertificate.revoke_changeset(user_certificate, attrs)
    )
    |> Ecto.Multi.update_all(
      :revoke_certificate,
      fn %{revoke_user_certificate: user_certificate} ->
        from(c in Certificate,
          where: c.id == ^user_certificate.certificate_id,
          update: [
            set: [
              status: :revoked,
              revocation_date: ^revocation_date,
              revocation_reason: ^revocation_reason
            ]
          ]
        )
      end,
      []
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{revoke_user_certificate: revoked}} ->
        {:ok, revoked, dgettext("certificates", "certificate_revokation_succeded")}

      {:error, :revoke_user_certificate, changeset, _} ->
        {:error, changeset, dgettext("certificates", "certificate_revokation_failed")}
    end
  end

  def delete_certificate(:user, %UserCertificate{} = user_certificate) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete_user_certificate, user_certificate)
    |> Ecto.Multi.delete(:delete_certificate, user_certificate.certificate)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, dgettext("certificates", "certificate_deletion_succeed")}

      {:error, :delete_user_certificate} ->
        {:error, dgettext("certificates", "user_certificate_deletion_failed")}

      {:error, :delete_certificate} ->
        {:error, dgettext("certificates", "certificate_deletion_succeed")}
    end
  end

  def delete_certificate(:org, %OrgCertificate{} = org_certificate) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete_org_certificate, org_certificate)
    |> Ecto.Multi.delete(:delete_certificate, org_certificate.certificate)
    |> Repo.transaction()
    |> case do
      {:ok, _} ->
        {:ok, dgettext("certificates", "certificate_deletion_succeed")}

      {:error, :delete_user_certificate} ->
        {:error, dgettext("certificates", "org_certificate_deletion_failed")}

      {:error, :delete_certificate} ->
        {:error, dgettext("certificates", "certificate_deletion_failed")}
    end
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
end

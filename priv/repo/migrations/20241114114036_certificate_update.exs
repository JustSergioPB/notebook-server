defmodule NotebookServer.Repo.Migrations.CertificateUpdate do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE certificate_status AS ENUM ('active', 'revoked', 'rotated')"
    execute "CREATE TYPE certificate_platform AS ENUM ('web2', 'web3')"
    execute "CREATE TYPE certificate_level AS ENUM ('entity', 'intermediate', 'root')"

    create table(:certificates) do
      add :public_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :status, :certificate_status, default: "active", null: false
      add :platform, :certificate_platform, default: "web2", null: false
      add :level, :certificate_level, default: "entity", null: false
      add :public_key_pem, :text, null: false
      add :cert_pem, :text, null: false
      add :revocation_reason, :string
      add :revocation_date, :utc_datetime
      add :expiration_date, :utc_datetime, null: false
      add :issued_by_id, references(:certificates, on_delete: :delete_all)
      add :replaced_by_id, references(:certificates, on_delete: :delete_all)
    end

    alter table(:org_certificates) do
      remove :issued_by_id
      remove :uuid
      remove :replaces_id
      remove :expiration_date
      remove :revocation_date
      remove :revocation_reason
      remove :platform
      remove :status
      remove :level
      add :certificate_id, references(:certificates, on_delete: :delete_all), null: false
    end

    alter table(:user_certificates) do
      remove :issued_by_root_id
      remove :issued_by_id
      remove :uuid
      remove :replaces_id
      remove :expiration_date
      remove :revocation_date
      remove :revocation_reason
      remove :platform
      remove :status
      add :certificate_id, references(:certificates, on_delete: :delete_all), null: false
    end

    execute "drop type org_certificate_status"
    execute "drop type org_certificate_level"
    execute "drop type org_certificate_platform"
  end
end

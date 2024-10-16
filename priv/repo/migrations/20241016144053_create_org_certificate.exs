defmodule NotebookServer.Repo.Migrations.CreateOrgCertificate do
  use Ecto.Migration

  def change do
    execute "create type org_certificate_status as enum('active', 'revoked', 'rotated')"
    execute "create type org_certificate_level as enum('root', 'intermediate')"
    execute "create type org_certificate_platform as enum('web2', 'web3')"


    create table(:org_certificate) do
      add :level, :org_certificate_level
      add :status, :org_certificate_status
      add :cert_pem, :binary
      add :platform, :org_certificate_platform
      add :revocation_reason, :string
      add :revocation_date, :utc_datetime
      add :expiration_date, :utc_datetime
      add :org_id, references(:orgs, on_delete: :nothing)
      add :replaces_id, references(:org_certificate, on_delete: :nothing)
      timestamps(type: :utc_datetime)
    end

    create index(:org_certificate, [:org_id])
    create index(:org_certificate, [:replaces_id])
  end
end

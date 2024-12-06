defmodule NotebookServer.Repo.Migrations.BigBang do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    execute "CREATE TYPE org_status AS ENUM ('active', 'inactive', 'banned')"

    create table(:orgs) do
      add :name, :citext, null: false
      add :email, :citext, null: false
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :status, :org_status, null: false, default: "inactive"

      timestamps(type: :utc_datetime)
    end

    create unique_index(:orgs, [:name])
    create unique_index(:orgs, [:email])

    execute "CREATE TYPE user_role AS ENUM ('admin', 'org_admin', 'issuer')"
    execute "CREATE TYPE user_status AS ENUM ('active', 'inactive', 'banned')"
    execute "CREATE TYPE user_language AS ENUM ('es', 'en')"

    create table(:users) do
      add :name, :string, size: 50
      add :last_name, :string, size: 50
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime
      add :role, :user_role, null: false, default: "issuer"
      add :status, :user_status, null: false, default: "inactive"
      add :language, :user_language, default: "es"
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create unique_index(:users, [:email, :name, :last_name])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    execute "CREATE TYPE certificate_status AS ENUM ('active', 'rotated', 'revoked')"
    execute "CREATE TYPE certificate_level AS ENUM ('root', 'intermediate', 'entity')"

    create table(:certificates) do
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :status, :certificate_status, null: false, default: "active"
      add :level, :certificate_level, null: false, default: "entity"
      add :public_key_pem, :text, null: false
      add :cert_pem, :text, null: false
      add :revocation_reason, :string
      add :revocation_date, :utc_datetime
      add :expiration_date, :utc_datetime, null: false
      add :issued_by_id, references(:certificates, on_delete: :delete_all)
      add :replaces_id, references(:certificates)

      timestamps(type: :utc_datetime)
    end

    create table(:org_certificates) do
      add :certificate_id, references(:certificates, on_delete: :delete_all), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:user_certificates) do
      add :certificate_id, references(:certificates, on_delete: :delete_all), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:schemas) do
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :title, :citext, null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:schemas, [:org_id, :title])

    execute "CREATE TYPE schema_version_status AS ENUM ('draft', 'published', 'archived')"

    create table(:schema_versions) do
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :version, :integer, null: false
      add :content, :map, null: false
      add :status, :schema_version_status, null: false, default: "draft"
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:schema_versions, [:schema_id, :version])

    create table(:credentials) do
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :content, :map, null: false
      add :schema_version_id, references(:schema_versions, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:org_credentials) do
      add :credential_id, references(:credentials, on_delete: :delete_all), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:user_credentials) do
      add :credential_id, references(:credentials, on_delete: :delete_all), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    execute "CREATE TYPE bridge_type AS ENUM ('email')"

    create table(:bridges) do
      add :public_id, :uuid, default: fragment("gen_random_uuid()"), null: false
      add :active, :boolean, null: false
      add :type, :bridge_type, null: false, default: "email"
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:email_bridges) do
      add :email, :citext, null: false
      add :code, :integer, null: false
      add :bridge_id, references(:bridges, on_delete: :delete_all), null: false
      add :org_credential_id, references(:org_credentials, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end
  end
end

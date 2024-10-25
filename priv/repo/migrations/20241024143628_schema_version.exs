defmodule NotebookServer.Repo.Migrations.SchemaVersion do
  use Ecto.Migration

  def change do
    alter table(:schemas) do
      remove :credential_subject
      remove :user_id
      remove :description
      remove :platform
      remove :status
      remove :replaces_id

      modify :title, :string,
        null: false,
        unique: true,
        size: 50,
        from: {:string, null: true, unique: false, size: 255}

      modify :org_id, references(:orgs, on_delete: :delete_all),
        from: references(:orgs, on_delete: :nothing)
    end

    create index(:schemas, [:title], unique: true)

    execute "DROP TYPE schema_platform"
    execute "DROP TYPE schema_status"
    execute "CREATE TYPE schema_version_platform AS ENUM ('web2', 'web3')"
    execute "CREATE TYPE schema_version_status AS ENUM ('draft', 'published', 'archived')"

    create table(:schema_versions) do
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :credential_subject, :map, null: false
      add :version_number, :integer, null: false
      add :status, :schema_version_status, null: false, default: "draft"
      add :platform, :schema_version_platform, null: false, default: "web2"
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create index(:schema_versions, [:schema_id])

    create unique_index(:schema_versions, [:schema_id, :status],
             where: "status = 'published'",
             name: :unique_published_version
           )
  end
end

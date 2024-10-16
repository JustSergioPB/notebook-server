defmodule NotebookServer.Repo.Migrations.SchemaUpgrade do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE schema_platform AS ENUM ('web2', 'web3')"
    execute "CREATE TYPE schema_status AS ENUM ('draft', 'published', 'archived')"

    alter table(:schemas) do
      add :title, :string
      add :description, :string
      add :platform, :schema_platform
      add :status, :schema_status
      add :replaces_id, references(:schemas)
    end

    create index(:schemas, [:replaces_id])

    rename table(:schemas), :context, to: :credential_subject
  end
end

defmodule NotebookServer.Repo.Migrations.SchemaVersionInCredential do
  use Ecto.Migration

  def change do
    alter table(:credentials) do
      add :schema_version_id, references(:schema_versions, on_delete: :nothing), null: false
    end

    execute "DROP INDEX schemas_title_index"

    create unique_index(:schemas, [:title, :org_id], name: :unique_schema_title_by_org)
  end
end

defmodule NotebookServer.Repo.Migrations.SchemaVersionDraftUnique do
  use Ecto.Migration

  def change do
    create unique_index(:schema_versions, [:schema_id, :status],
             where: "status = 'draft'",
             name: :unique_draft_version
           )
  end
end

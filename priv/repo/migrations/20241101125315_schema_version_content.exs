defmodule NotebookServer.Repo.Migrations.SchemaVersionContent do
  use Ecto.Migration

  def change do
    rename table(:schema_versions), :content, to: :credential_subject
  end
end

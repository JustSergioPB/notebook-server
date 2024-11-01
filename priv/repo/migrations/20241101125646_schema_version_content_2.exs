defmodule NotebookServer.Repo.Migrations.SchemaVersionContent2 do
  use Ecto.Migration

  def change do
    rename table(:schema_versions), :credential_subject, to: :content
  end
end

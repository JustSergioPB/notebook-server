defmodule NotebookServer.Repo.Migrations.CredentialRemoveSchemaId do
  use Ecto.Migration

  def change do
    alter table(:credentials) do
      remove :schema_id
    end
  end
end

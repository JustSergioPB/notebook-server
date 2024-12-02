defmodule NotebookServer.Repo.Migrations.RemoveVersion do
  use Ecto.Migration

  def change do
    alter table(:schema_versions) do
      remove :version
      remove :description
    end
  end
end

defmodule NotebookServer.Repo.Migrations.AddVersion do
  use Ecto.Migration

  def change do
    alter table(:schema_versions) do
      add :version, :integer, null: false, default: 0
    end
  end
end

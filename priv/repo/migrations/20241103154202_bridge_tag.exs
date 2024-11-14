defmodule NotebookServer.Repo.Migrations.BridgeTag do
  use Ecto.Migration

  def change do
    alter table(:bridges) do
      add :tag, :string, null: false, size: 50, unique: true
    end
  end
end

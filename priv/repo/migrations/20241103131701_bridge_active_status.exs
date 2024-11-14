defmodule NotebookServer.Repo.Migrations.BridgeActiveStatus do
  use Ecto.Migration

  def change do
    alter table(:bridges) do
      add :active, :boolean, null: false, default: false
    end
  end
end

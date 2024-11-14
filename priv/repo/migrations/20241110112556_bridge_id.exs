defmodule NotebookServer.Repo.Migrations.BridgeId do
  use Ecto.Migration

  def change do
    rename table(:evidence_bridges), :evidence_bridge_id, to: :bridge_id
  end
end

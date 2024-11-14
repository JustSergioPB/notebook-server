defmodule NotebookServer.Repo.Migrations.EvidenceBridgePublicId do
  use Ecto.Migration

  def change do
    alter table(:evidence_bridges) do
      add :public_id, :uuid, null: false
    end
  end
end

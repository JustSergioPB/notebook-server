defmodule NotebookServer.Repo.Migrations.EvidenceBridge do
  use Ecto.Migration

  def change do
    rename table(:org_bridges), to: table(:evidence_bridges)
    rename table(:email_bridges), to: table(:email_evidence_bridges)

    alter table(:bridges) do
      remove :schema_id
      remove :name
      remove :active
    end

    alter table(:evidence_bridges) do
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false
    end

    rename table(:evidence_bridges), :bridge_id, to: :evidence_bridge_id

    alter table(:email_evidence_bridges) do
      add :evidence_bridge_id, references(:evidence_bridges, on_delete: :delete_all), null: false
    end
  end
end

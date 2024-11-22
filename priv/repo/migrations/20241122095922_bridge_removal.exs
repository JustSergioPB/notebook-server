defmodule NotebookServer.Repo.Migrations.BridgeRemoval do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE bridge_type AS ENUM ('email')"

    alter table(:evidence_bridges) do
      add :type, :bridge_type, null: false
      remove :bridge_id
    end

    drop table(:bridges)
    rename table(:evidence_bridges), to: table(:bridges)
    rename table(:email_evidence_bridges), to: table(:email_bridges)

    rename table(:email_bridges), :evidence_bridge_id, to: :bridge_id

    alter table(:email_bridges) do
      remove :org_id
    end
  end
end

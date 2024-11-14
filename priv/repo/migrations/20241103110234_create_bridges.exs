defmodule NotebookServer.Repo.Migrations.CreateBridges do
  use Ecto.Migration

  def change do
    create table(:bridges) do
      add :name, :string, null: false
      add :schema_id, references(:schemas, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:org_bridges) do
      add :active, :boolean, default: false, null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :bridge_id, references(:bridges, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:bridges, [:schema_id])
    create unique_index(:bridges, [:name])
    create unique_index(:org_bridges, [:bridge_id, :org_id], name: "unique_bridge_per_company")
  end
end

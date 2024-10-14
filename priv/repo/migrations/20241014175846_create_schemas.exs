defmodule NotebookServer.Repo.Migrations.CreateSchemas do
  use Ecto.Migration

  def change do
    create table(:schemas) do
      add :context, :map
      add :org_id, references(:orgs, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:schemas, [:org_id])
  end
end

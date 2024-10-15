defmodule NotebookServer.Repo.Migrations.CreateCredentials do
  use Ecto.Migration

  def change do
    create table(:credentials) do
      add :content, :map
      add :org_id, references(:orgs, on_delete: :nothing)
      add :issuer_id, references(:users, on_delete: :nothing)
      add :schema_id, references(:schemas, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:credentials, [:org_id])
    create index(:credentials, [:issuer_id])
    create index(:credentials, [:schema_id])
  end
end

defmodule NotebookServer.Repo.Migrations.CreatePublicKeys do
  use Ecto.Migration

  def change do
    create table(:public_keys) do
      add :key, :binary
      add :expiration_date, :utc_datetime
      add :status, :string
      add :user_id, references(:users, on_delete: :nothing)
      add :org_id, references(:orgs, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:public_keys, [:user_id])
    create index(:public_keys, [:org_id])
  end
end

defmodule NotebookServer.Repo.Migrations.KeyRotation do
  use Ecto.Migration

  def change do
    alter table(:public_keys) do
      add :replaces_id, references(:public_keys)
    end

    create index(:public_keys, [:replaces_id])
  end
end

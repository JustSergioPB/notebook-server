defmodule NotebookServer.Repo.Migrations.HolderRole do
  use Ecto.Migration

  def change do
    execute "ALTER TYPE user_role RENAME VALUE 'user' TO 'issuer';"

    alter table(:schemas) do
      add :user_id, references(:users, on_delete: :nothing)
    end

    create index(:schemas, [:user_id])
  end
end

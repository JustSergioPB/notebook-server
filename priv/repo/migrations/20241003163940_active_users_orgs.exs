defmodule NotebookServer.Repo.Migrations.ActiveUsersOrgs do
  use Ecto.Migration

  def change do
    execute "DROP TYPE user_status CASCADE"
    execute "CREATE TYPE user_status AS ENUM ('active', 'inactive')"

    alter table(:users) do
      add :status, :user_status, default: "active"
      add :confirmed_at, :utc_datetime
    end

    execute "DROP TYPE org_status CASCADE"
    execute "CREATE TYPE org_status AS ENUM ('active', 'inactive')"

    alter table(:orgs) do
      add :status, :org_status, default: "active"
    end
  end
end
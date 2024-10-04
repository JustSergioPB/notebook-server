defmodule NotebookServer.Repo.Migrations.CreateOrgs do
  use Ecto.Migration

  def change do
    create table(:orgs) do
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    execute "CREATE TYPE user_role AS ENUM ('admin', 'org_admin', 'user')"

    alter table(:users) do
      add :role, :user_role, default: "user"
      add :org_id, references(:orgs)
    end
  end
end

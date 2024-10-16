defmodule NotebookServer.Repo.Migrations.OrgLevel do
  use Ecto.Migration

  def change do
    execute "create type org_level as enum('root', 'intermediate')"

    alter table(:orgs) do
      add :level, :org_level, default: "intermediate"
    end
  end
end

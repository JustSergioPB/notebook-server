defmodule NotebookServer.Repo.Migrations.RemoveOrgLevel do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      remove :level
    end

    execute "drop type org_level"
  end
end

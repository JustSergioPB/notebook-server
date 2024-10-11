defmodule NotebookServer.Repo.Migrations.Restricitions do
  use Ecto.Migration

  def change do
    execute "ALTER TYPE user_status ADD VALUE 'stopped'"

    execute "ALTER TYPE org_status ADD VALUE 'stopped'"
  end
end

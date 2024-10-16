defmodule NotebookServer.Repo.Migrations.Banned do
  use Ecto.Migration

  def change do
    execute "ALTER TYPE user_status RENAME VALUE 'stopped' TO 'banned'"
    execute "ALTER TYPE org_status RENAME VALUE 'stopped' TO 'banned'"
  end
end

defmodule NotebookServer.Repo.Migrations.UserLang do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE language AS ENUM ('en', 'es')", "DROP TYPE language"

    alter table(:users) do
      add :language, :language, default: "es"
    end
  end
end

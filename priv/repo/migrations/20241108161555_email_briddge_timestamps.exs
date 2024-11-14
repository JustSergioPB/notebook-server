defmodule NotebookServer.Repo.Migrations.EmailBriddgeTimestamps do
  use Ecto.Migration

  def change do
    alter table(:email_bridges) do
      timestamps(type: :utc_datetime)
    end
  end
end

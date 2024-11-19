defmodule NotebookServer.Repo.Migrations.CredentialTimestamps do
  use Ecto.Migration

  def change do
    alter table(:certificates) do
      timestamps(type: :utc_datetime)
    end
  end
end

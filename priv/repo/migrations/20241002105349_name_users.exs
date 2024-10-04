defmodule NotebookServer.Repo.Migrations.NameUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string
      add :last_name, :string
    end
  end
end

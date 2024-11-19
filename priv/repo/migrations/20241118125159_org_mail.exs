defmodule NotebookServer.Repo.Migrations.OrgMail do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :email, :string, null: false, default: ""
    end
  end
end

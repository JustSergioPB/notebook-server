defmodule NotebookServer.Repo.Migrations.UserCredentialOrgId do
  use Ecto.Migration

  def change do
    alter table(:user_credentials) do
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
    end
  end
end

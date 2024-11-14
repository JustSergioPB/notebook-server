defmodule NotebookServer.Repo.Migrations.EmailBridgeOrgId do
  use Ecto.Migration

  def change do
    alter table(:email_bridges) do
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
    end
  end
end

defmodule NotebookServer.Repo.Migrations.EmailBridgeNullableOrgId do
  use Ecto.Migration

  def change do
    alter table(:email_bridges) do
      modify :org_credential_id, :integer, null: true, from: {:integer, null: false}
    end
  end
end

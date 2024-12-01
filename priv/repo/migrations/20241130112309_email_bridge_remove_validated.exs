defmodule NotebookServer.Repo.Migrations.EmailBridgeRemoveValidated do
  use Ecto.Migration

  def change do
    alter table(:email_bridges) do
      remove :validated
      modify :org_credential_id, references(:org_credentials, on_delete: :nothing) ,null: false
    end
  end
end

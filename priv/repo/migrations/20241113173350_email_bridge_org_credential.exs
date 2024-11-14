defmodule NotebookServer.Repo.Migrations.EmailBridgeOrgCredential do
  use Ecto.Migration

  def change do
    alter table(:email_evidence_bridges) do
      remove :credential_id
      add :org_credential_id, references(:org_credentials, on_delete: :delete_all), null: false
    end
  end
end

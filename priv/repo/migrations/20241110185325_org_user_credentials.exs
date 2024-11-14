defmodule NotebookServer.Repo.Migrations.OrgUserCredentials do
  use Ecto.Migration

  def change do
    alter table(:credentials) do
      remove :org_id
      remove :issuer_id
    end

    create table(:org_credentials) do
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :credential_id, references(:credentials, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create table(:user_credentials) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :credential_id, references(:credentials, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end
  end
end

defmodule NotebookServer.Repo.Migrations.EmailBridge do
  use Ecto.Migration

  def change do
    create table(:email_bridges) do
      add :email, :string, null: false
      add :code, :integer, null: false
      add :validated, :boolean, null: false, default: false
      add :credential_id, references(:credentials, on_delete: :nothing)
    end
  end
end

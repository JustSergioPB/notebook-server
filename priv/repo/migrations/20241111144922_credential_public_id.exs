defmodule NotebookServer.Repo.Migrations.CredentialPublicId do
  use Ecto.Migration

  def change do
    alter table(:credentials) do
      add :public_id, :uuid, null: false, default: fragment("gen_random_uuid()")
    end
  end
end

defmodule NotebookServer.Repo.Migrations.IssuedByRoot do
  use Ecto.Migration

  def change do
    alter table(:user_certificates) do
      add :issued_by_root_id, references(:org_certificates)
    end
  end
end

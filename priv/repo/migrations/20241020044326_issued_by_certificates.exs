defmodule NotebookServer.Repo.Migrations.IssuedByCertificates do
  use Ecto.Migration

  def change do
    alter table(:user_certificates) do
      add :issued_by_id, references(:org_certificates)
    end

    alter table(:org_certificates) do
      add :issued_by_id, references(:org_certificates)
    end
  end
end

defmodule NotebookServer.Repo.Migrations.IdForCertificates do
  use Ecto.Migration

  def change do
    alter table(:user_certificates) do
      add :uuid, :string
    end

    alter table(:org_certificates) do
      add :uuid, :string
    end
  end
end

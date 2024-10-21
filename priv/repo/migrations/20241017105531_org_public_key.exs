defmodule NotebookServer.Repo.Migrations.OrgPublicKey do
  use Ecto.Migration

  def change do
    rename table(:org_certificate), to: table(:org_certificates)

    alter table(:org_certificates) do
      add :public_key, :binary
    end
  end
end

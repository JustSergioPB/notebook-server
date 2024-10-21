defmodule NotebookServer.Repo.Migrations.RemoveKeys do
  use Ecto.Migration

  def change do
    alter table(:org_certificates) do
      remove :public_key_pem
      remove :cert_pem
    end

    alter table(:user_certificates) do
      remove :public_key_pem
      remove :cert_pem
    end
  end
end

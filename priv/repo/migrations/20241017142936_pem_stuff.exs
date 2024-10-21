defmodule NotebookServer.Repo.Migrations.PemStuff do
  use Ecto.Migration

  def change do
    alter table(:org_certificates) do
      remove :public_key
      remove :cert_pem
      add :cert_pem, :string
      add :public_key_pem, :string
    end

    alter table(:user_certificates) do
      remove :signing_public_key_pem
      remove :cert_pem
      add :cert_pem, :string
      add :public_key_pem, :string
    end
  end
end

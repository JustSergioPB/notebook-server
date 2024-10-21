defmodule NotebookServer.Repo.Migrations.UserCertificate do
  use Ecto.Migration

  def change do
    rename table(:public_keys), to: table(:user_certificates)

    alter table(:user_certificates) do
      add :cert_pem, :binary
      add :revocation_date, :utc_datetime
      add :revocation_reason, :string
    end

    rename table(:user_certificates), :key, to: :signing_public_key_pem
  end
end

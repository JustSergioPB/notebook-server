defmodule NotebookServer.Repo.Migrations.KeyPairUpgrade do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE key_platform AS ENUM ('web2', 'web3')"
    alter table(:public_keys) do
      add :platform, :key_platform, default: "web2"
    end
  end
end

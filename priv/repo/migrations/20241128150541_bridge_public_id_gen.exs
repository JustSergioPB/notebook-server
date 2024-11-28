defmodule NotebookServer.Repo.Migrations.BridgePublicIdGen do
  use Ecto.Migration

  def change do
    alter table(:bridges) do
      modify :public_id, :uuid, default: fragment("gen_random_uuid()")
    end
  end
end

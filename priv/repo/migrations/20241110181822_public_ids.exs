defmodule NotebookServer.Repo.Migrations.PublicIds do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :public_id, :uuid, null: false, default: fragment("gen_random_uuid()")
    end

    alter table(:users) do
      add :public_id, :uuid, null: false, default: fragment("gen_random_uuid()")
    end
  end
end

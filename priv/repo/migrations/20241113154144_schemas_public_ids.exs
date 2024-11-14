defmodule NotebookServer.Repo.Migrations.SchemasPublicIds do
  use Ecto.Migration

  def change do
    alter table(:schema_versions) do
      add :public_id, :uuid, null: false, default: fragment("gen_random_uuid()")
    end

    alter table(:schemas) do
      add :public_id, :uuid, null: false, default: fragment("gen_random_uuid()")
    end
  end
end

defmodule NotebookServer.Repo.Migrations.BridgeNameLimit do
  use Ecto.Migration

  def change do
    alter table(:bridges) do
      modify :name, :string,
        null: false,
        unique: true,
        size: 50,
        from: {:string, null: true, unique: false, size: 255}
    end
  end
end

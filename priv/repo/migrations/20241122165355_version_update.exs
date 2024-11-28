defmodule NotebookServer.Repo.Migrations.VersionUpdate do
  use Ecto.Migration

  def change do
    rename table(:schema_versions), :version_number, to: :version
  end
end

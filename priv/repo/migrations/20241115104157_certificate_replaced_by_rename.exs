defmodule NotebookServer.Repo.Migrations.CertificateReplacedByRename do
  use Ecto.Migration

  def change do
    rename table(:certificates), :replaced_by_id, to: :replaces_id
  end
end

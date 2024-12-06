defmodule NotebookServer.Schemas.SchemaVersion do
  use Ecto.Schema
  import Ecto.Changeset

  # TODO create index with version and schema_id, to avoid having two versions with the same version number

  schema "schema_versions" do
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    field :version, :integer, default: 0
    field :content, :map
    field :public_id, :binary_id
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  def changeset(schema_version, attrs \\ %{}) do
    schema_version
    |> cast(attrs, [
      :status,
      :schema_id,
      :version,
      :content
    ])
    |> validate_required([:version, :content])
  end

  def publish_changeset(schema_version) do
    change(schema_version, status: :published)
  end

  def archive_changeset(schema_version) do
    change(schema_version, status: :archived)
  end
end

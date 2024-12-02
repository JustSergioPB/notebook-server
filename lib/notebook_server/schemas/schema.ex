defmodule NotebookServer.Schemas.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schemas" do
    field :title, :string
    field :public_id, :binary_id
    belongs_to :org, NotebookServer.Orgs.Org
    has_many :schema_versions, NotebookServer.Schemas.SchemaVersion

    timestamps(type: :utc_datetime)
  end

  def changeset(schema, attrs \\ %{}, opts \\ []) do
    schema
    |> cast(attrs, [:title, :org_id])
    |> validate_required([:title, :org_id])
    |> validate_length(:title, min: 2, max: 50)
    |> maybe_cast_schema_version(opts)
  end

  def maybe_cast_schema_version(changeset, opts \\ []) do
    create = Keyword.get(opts, :create, true)

    changeset =
      if create,
        do: changeset |> cast_assoc(:schema_versions, required: true),
        else: changeset

    changeset
  end
end

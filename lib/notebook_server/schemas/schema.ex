defmodule NotebookServer.Schemas.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "schemas" do
    field :title, :string
    field :public_id, :binary_id
    belongs_to :org, NotebookServer.Orgs.Org
    has_many :schema_versions, NotebookServer.Schemas.SchemaVersion, on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  def changeset(schema, attrs \\ %{}, opts \\ []) do
    should_update? = Keyword.get(opts, :update, false)

    schema =
      schema
      |> cast(attrs, [:title, :org_id, :public_id])
      |> validate_required([:title, :org_id, :public_id])
      |> validate_length(:title, min: 2, max: 50)

    schema =
      if should_update?,
        do: schema |> cast_assoc(:schema_versions, required: true),
        else: schema |> cast_assoc(:schema_versions, required: true)

    schema
  end
end

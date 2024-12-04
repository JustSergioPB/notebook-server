defmodule NotebookServer.Schemas.SchemaContent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :schema, :string, default: "https://json-schema.org/draft/2020-12/schema"
    field :title, :string
    field :description, :string
    field :type, :string, default: "object"
    embeds_one :properties, NotebookServer.Schemas.SchemaProperties, on_replace: :update

    field :required, {:array, :string},
      default: [
        # TODO: add the @
        "context",
        "title",
        "type",
        "issuer",
        # TODO: use camel
        "credential_subject",
        # TODO: use camel
        "credential_schema",
        "proof"
      ]
  end

  def changeset(schema_content, attrs \\ %{}) do
    schema_content
    |> cast(attrs, [:title, :description])
    |> validate_required([:title])
    |> cast_embed(:properties, required: true)
  end
end

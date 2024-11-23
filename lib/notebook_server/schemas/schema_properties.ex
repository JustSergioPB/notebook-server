defmodule NotebookServer.Schemas.SchemaProperties do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    # TODO: add the @
    field :context, :map,
      default: %{
        const: ["https://www.w3.org/ns/credentials/v2"]
      }

    embeds_one :title, NotebookServer.Schemas.SchemaTitle
    embeds_one :description, NotebookServer.Schemas.SchemaDescription

    field :type, :map,
      default: %{
        const: ["VerifiableCredential"]
      }

    field :issuer, :map, default: %{type: "string", format: "uri"}
    # TODO: use camel
    embeds_one :credential_subject, NotebookServer.Schemas.SchemaCredentialSubject

    # TODO: use camel
    field :credential_schema, :map,
      default: %{
        type: "object",
        properties: %{
          id: %{
            type: "string",
            format: "uri"
          },
          type: %{
            const: "JsonSchema"
          }
        },
        required: ["id", "type"]
      }
  end

  def changeset(schema_properties, attrs \\ %{}) do
    schema_properties
    |> cast(attrs, [])
    |> cast_embed(:title, required: true)
    |> cast_embed(:credential_subject, required: true)
    |> maybe_cast_description()
  end

  defp maybe_cast_description(changeset) do
    description = changeset |> get_field(:description)

    changeset =
      if is_binary(description) && description != "",
        do: changeset |> cast_embed(:description),
        else: changeset

    changeset
  end
end

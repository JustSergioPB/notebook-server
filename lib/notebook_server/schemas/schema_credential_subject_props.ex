defmodule NotebookServer.Schemas.SchemaCredentialSubjectProps do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :id, :map,
      default: %{
        type: "string",
        pattern: "#TODO"
      }

    field :content, :map
  end

  def changeset(schema_credential_subject_props, attrs \\ %{}) do
    attrs =
      with true <- is_binary(attrs["content"]),
           {:ok, decoded_value} <- Jason.decode(attrs["content"]) do
        Map.put(attrs, "content", decoded_value)
      else
        _ -> attrs
      end

    schema_credential_subject_props
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end

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
    schema_credential_subject_props
    |> cast(attrs, [:content])
    |> validate_required([:content])
  end
end

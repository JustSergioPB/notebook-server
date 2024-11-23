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
    field :raw, :string, default: "{}"
  end

  def changeset(schema_credential_subject_props, attrs \\ %{}) do
    schema_credential_subject_props
    |> cast(attrs, [:raw])
    |> validate_raw()
  end

  def validate_raw(changeset) do
    raw = changeset |> get_field(:raw)

    changeset =
      case Jason.decode(raw) do
        {:ok, content} -> changeset |> put_change(:content, content)
        {:error, _} -> changeset |> add_error(:raw, "invalid_json")
      end

    changeset
  end
end

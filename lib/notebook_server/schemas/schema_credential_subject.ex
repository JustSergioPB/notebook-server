defmodule NotebookServer.Schemas.SchemaCredentialSubject do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :type, :string, default: "object"
    embeds_one :properties, NotebookServer.Schemas.SchemaCredentialSubjectProps
    field :required, {:array, :string}, default: ["id", "content"]
  end

  def changeset(schema_credential_subject, attrs \\ %{}) do
    schema_credential_subject |> cast(attrs, []) |> cast_embed(:properties, required: true)
  end
end

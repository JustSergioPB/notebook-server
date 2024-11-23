defmodule NotebookServer.Schemas.SchemaType do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :const, {:array, :string}, default: ["VerifiableCredential"]
  end

  def changeset(schema_type, attrs \\ %{}) do
    schema_type |> cast(attrs, [:const])
  end
end

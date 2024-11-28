defmodule NotebookServer.Schemas.SchemaDescription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :const, :string
  end

  def changeset(schema_description, attrs \\ %{}) do
    schema_description |> cast(attrs, [:const]) |> validate_required([:const])
  end
end

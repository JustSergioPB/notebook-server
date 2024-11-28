defmodule NotebookServer.Schemas.SchemaTitle do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :const, :string
  end

  def changeset(schema_title, attrs \\ %{}) do
    schema_title |> cast(attrs, [:const]) |> validate_required([:const])
  end
end

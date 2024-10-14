defmodule NotebookServer.Credentials.Schema do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "schemas" do
    field :context, :map, default: %{}
    belongs_to :org, NotebookServer.Orgs.Org

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(schema, attrs) do
    attrs =
      with true <- is_binary(attrs["context"]),
           {:ok, decoded_value} <- Jason.decode(attrs["context"]) do
        Map.put(attrs, "context", decoded_value)
      else
        _ -> attrs
      end

    schema
    |> cast(attrs, [:context, :org_id])
    |> validate_required([:context, :org_id])
  end
end

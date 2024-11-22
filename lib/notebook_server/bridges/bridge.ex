defmodule NotebookServer.Bridges.Bridge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bridges" do
    field :active, :boolean, default: false
    field :public_id, :binary_id, default: Ecto.UUID.generate()
    field :type, Ecto.Enum, values: [:email]
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bridge, attrs) do
    bridge
    |> cast(attrs, [:active, :type, :org_id, :schema_id])
    |> validate_required([:active, :type, :org_id, :schema_id])
  end

  def map_to_wall(bridge) do
    schema = bridge |> Map.get(:schema)

    published_version =
      schema
      |> Map.get(:schema_versions)
      |> Enum.filter(fn sv -> sv.status == :published end)
      |> Enum.at(0)

    published_version = published_version |> Map.put(:title, schema.title)

    bridge |> Map.merge(%{published_version: published_version})
  end
end

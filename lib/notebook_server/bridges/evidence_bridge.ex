defmodule NotebookServer.Bridges.EvidenceBridge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "evidence_bridges" do
    field :active, :boolean, default: false
    field :public_id, :binary_id, default: Ecto.UUID.generate
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :bridge, NotebookServer.Bridges.Bridge
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(evidence_bridge, attrs) do
    evidence_bridge
    |> cast(attrs, [:active, :org_id, :bridge_id, :schema_id])
    |> validate_required([:active, :org_id, :bridge_id, :schema_id])
  end

  def map_to_wall(evidence_bridge) do
    schema = evidence_bridge |> Map.get(:schema)

    published_version =
      schema
      |> Map.get(:schema_versions)
      |> Enum.filter(fn sv -> sv.status == :published end)
      |> Enum.at(0)

    published_version = published_version |> Map.put(:title, schema.title)

    evidence_bridge |> Map.merge(%{published_version: published_version})
  end
end

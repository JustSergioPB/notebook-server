defmodule NotebookServer.Bridges.Bridge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bridges" do
    field :active, :boolean, default: false
    field :public_id, :binary_id
    field :type, Ecto.Enum, values: [:email], default: :email
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bridge, attrs) do
    bridge
    |> cast(attrs, [:active, :type, :org_id, :public_id])
    |> validate_required([:active, :type, :org_id, :public_id])
    |> cast_assoc(:schema, required: true)
  end
end

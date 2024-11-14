defmodule NotebookServer.Bridges.Bridge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bridges" do
    field :tag, :string
    has_many :evidence_bridges, NotebookServer.Bridges.EvidenceBridge

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bridge, attrs) do
    bridge
    |> cast(attrs, [:tag])
    |> validate_required([:tag])
  end
end

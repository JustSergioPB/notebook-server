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
  def changeset(bridge, attrs \\ %{}, opts \\ []) do
    bridge
    |> cast(attrs, [:active, :type, :org_id])
    |> validate_required([:active, :type, :org_id])
    |> maybe_cast_schema(opts)
  end

  def maybe_cast_schema(changeset, opts \\ []) do
    create = Keyword.get(opts, :create, true)

    if create,
      do: changeset |> cast_assoc(:schema, required: true),
      else: changeset
  end
end

defmodule NotebookServer.Bridges.EmailBridge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "email_bridges" do
    field :email, :string
    field :code, :integer
    belongs_to :org_credential, NotebookServer.Credentials.OrgCredential
    belongs_to :bridge, NotebookServer.Bridges.Bridge

    timestamps(type: :utc_datetime)
  end

  def changeset(email_bridge, attrs \\ %{}, opts \\ []) do
    email_bridge
    |> cast(attrs, [:email, :code, :bridge_id])
    |> validate_required([:email, :code, :bridge_id])
    |> validate_number(:code, greater_than: 99_999, less_than: 1_000_000)
    |> maybe_cast_credential(opts)
  end

  def maybe_cast_credential(changeset, opts \\ []) do
    create = Keyword.get(opts, :create, false)

    if create,
      do: changeset |> cast_assoc(:org_credential, required: true),
      else: changeset
  end

  def validate_changeset(email_bridge) do
    change(email_bridge, validated: true)
  end
end

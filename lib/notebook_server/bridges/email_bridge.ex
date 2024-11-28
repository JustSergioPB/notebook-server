defmodule NotebookServer.Bridges.EmailBridge do
  use Ecto.Schema
  import Ecto.Changeset

  schema "email_bridges" do
    field :email, :string
    field :code, :integer
    field :validated, :boolean, default: false
    belongs_to :org_credential, NotebookServer.Credentials.OrgCredential
    belongs_to :bridge, NotebookServer.Bridges.EvidenceBridge

    timestamps(type: :utc_datetime)
  end

  def changeset(email_bridge, attrs) do
    email_bridge
    |> cast(attrs, [:email, :code, :bridge_id])
    |> validate_required([:email, :code, :bridge_id])
    |> cast_assoc(:org_credential, required: true)
  end

  def validate_changeset(email_bridge) do
    change(email_bridge, validated: true)
  end
end

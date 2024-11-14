defmodule NotebookServer.Bridges.EmailEvidenceBridge do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "email_evidence_bridges" do
    field :email, :string
    field :code, :integer
    field :validated, :boolean, default: false
    belongs_to :org_credential, NotebookServer.Credentials.OrgCredential
    belongs_to :org, Notebook.Orgs.Org
    belongs_to :evidence_bridge, NotebookServer.Bridges.EvidenceBridge

    timestamps(type: :utc_datetime)
  end

  def changeset(email_bridge, attrs) do
    email_bridge
    |> cast(attrs, [:email, :org_id, :code, :evidence_bridge_id])
    |> validate_required([:email, :org_id, :code, :evidence_bridge_id],
      message: gettext("field_required")
    )
    |> cast_assoc(:org_credential, required: true)
  end

  def validate_changeset(email_bridge) do
    change(email_bridge, validated: true)
  end
end

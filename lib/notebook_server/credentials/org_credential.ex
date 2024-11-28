defmodule NotebookServer.Credentials.OrgCredential do
  use Ecto.Schema
  import Ecto.Changeset
  alias NotebookServer.Credentials.Credential

  schema "org_credentials" do
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :credential, Credential

    timestamps(type: :utc_datetime)
  end

  def changeset(org_credential, attrs) do
    org_credential
    |> cast(attrs, [:org_id])
    |> validate_required([:org_id])
    |> cast_assoc(:credential, required: true)
  end
end

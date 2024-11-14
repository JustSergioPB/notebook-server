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

  def gen_full(org_credential, org, schema_version) do
    domain_url = Application.get_env(:notebook_server, :url)

    credential =
      org_credential
      |> Map.get("credential")
      |> Credential.gen_full(
        "#{domain_url}/#{org.public_id}",
        schema_version
      )

    org_credential
    |> Map.merge(%{
      "org_id" => org.id,
      "credential" => credential
    })
  end
end

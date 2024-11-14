defmodule NotebookServer.Credentials.UserCredential do
  use Ecto.Schema
  import Ecto.Changeset
  alias NotebookServer.Credentials.Credential

  schema "user_credentials" do
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :credential, Credential

    timestamps(type: :utc_datetime)
  end

  def changeset(user_credential, attrs) do
    user_credential
    |> cast(attrs, [:user_id, :org_id])
    |> validate_required([:user_id, :org_id])
    |> cast_assoc(:credential, required: true)
  end

  def gen_full(user_credential, org, user, schema_version) do
    domain_url = Application.get_env(:notebook_server, :url)

    credential =
      user_credential
      |> Map.get("credential")
      |> Credential.gen_full(
        "#{domain_url}/#{org.public_id}/issuers/#{user.public_id}",
        schema_version
      )

    user_credential
    |> Map.merge(%{
      "org_id" => org.id,
      "user_id" => user.id,
      "credential" => credential
    })
  end
end

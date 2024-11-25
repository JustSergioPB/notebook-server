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
end

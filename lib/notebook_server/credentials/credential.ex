defmodule NotebookServer.Credentials.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  schema "credentials" do
    field :content, :map
    belongs_to :issuer, NotebookServer.Accounts.User
    belongs_to :schema, NotebookServer.Credentials.Schema
    belongs_to :org, NotebookServer.Orgs.Org

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:content])
    |> validate_required([])
  end
end

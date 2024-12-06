defmodule NotebookServer.Credentials.Credential do
  import Ecto.Changeset
  use Ecto.Schema

  schema "credentials" do
    field :public_id, :binary_id
    field :content, :map
    belongs_to :schema_version, NotebookServer.Schemas.SchemaVersion
    has_one :user_credential, NotebookServer.Credentials.UserCredential
    has_one :org_credential, NotebookServer.Credentials.OrgCredential

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:schema_version_id, :content])
    |> validate_required([:schema_version_id, :content])
  end

  #TODO: add validations for content
end

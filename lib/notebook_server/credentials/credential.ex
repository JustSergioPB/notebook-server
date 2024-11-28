defmodule NotebookServer.Credentials.Credential do
  import Ecto.Changeset
  use Ecto.Schema
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "credentials" do
    field :public_id, :binary_id
    embeds_one :content, NotebookServer.Credentials.VerifiableCredential
    belongs_to :schema_version, NotebookServer.Schemas.SchemaVersion
    has_one :user_credential, NotebookServer.Credentials.UserCredential
    has_one :org_credential, NotebookServer.Credentials.OrgCredential

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(credential, attrs) do
    credential
    |> cast(attrs, [:schema_version_id])
    |> validate_required([:schema_version_id], message: gettext("field_required"))
    |> cast_embed(:content, required: true)
  end
end

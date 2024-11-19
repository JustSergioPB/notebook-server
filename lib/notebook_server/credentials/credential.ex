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

  def gen_full(credential, issuer, schema_version) do
    domain_url = Application.get_env(:notebook_server, :url)

    content =
      credential
      |> Map.get("content")

    credential_subject =
      content
      |> Map.get("credential_subject")
      |> Map.put("id", "TODO")

    content =
      content
      |> Map.merge(%{
        "title" => schema_version.schema.title,
        "description" => schema_version.description,
        "issuer" => issuer,
        "credential_schema" => %{
          "id" => "#{domain_url}/#{schema_version.schema.public_id}/version/#{schema_version.public_id}"
        },
        "credential_subject" => credential_subject
      })

    credential |> Map.merge(%{"schema_version_id" => schema_version.id, "content" => content})
  end
end

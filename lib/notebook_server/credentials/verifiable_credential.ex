defmodule NotebookServer.Credentials.VerifiableCredential do
  import Ecto.Changeset
  use Ecto.Schema
  use Gettext, backend: NotebookServerWeb.Gettext

  @primary_key false
  embedded_schema do
    field :context, {:array, :string}, default: ["https://www.w3.org/ns/credentials/v2"]
    field :title, :string
    field :description, :string
    field :type, {:array, :string}, default: ["VerifiableCredential"]
    field :issuer, :string
    embeds_one :credential_subject, NotebookServer.Credentials.CredentialSubject
    embeds_one :credential_schema, NotebookServer.Credentials.CredentialSchema
  end

  def changeset(credential_content, attrs \\ %{}) do
    credential_content
    |> cast(attrs, [:context, :title, :description, :type, :issuer])
    |> validate_required([:issuer], message: gettext("field_required"))
    # TODO add validations to check that when provided type always have VerifiableCredential as one of the values
    # TODO add validations to check that when context is not empty
    |> cast_embed(:credential_schema, required: true)
    |> cast_embed(:credential_subject, required: true)
  end
end

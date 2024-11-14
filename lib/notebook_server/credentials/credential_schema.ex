defmodule NotebookServer.Credentials.CredentialSchema do
  import Ecto.Changeset
  use Ecto.Schema
  use Gettext, backend: NotebookServerWeb.Gettext

  @primary_key false
  embedded_schema do
    field :id, :string
    field :type, :string, default: "JsonSchema"
  end

  def changeset(credential_schema, attrs \\ %{}) do
    credential_schema
    |> cast(attrs, [:id, :type])
    |> validate_required([:id], message: gettext("field_required"))
  end
end

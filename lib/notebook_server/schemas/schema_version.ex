defmodule NotebookServer.Schemas.SchemaVersion do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Schemas.Schema

  schema "schema_versions" do
    field :title, :string, virtual: true
    field :description, :string
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    field :credential_subject, :map, default: %{}
    field :version_number, :integer
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  def changeset(schema_version, attrs) do
    attrs =
      with true <- is_binary(attrs["credential_subject"]),
           {:ok, decoded_value} <- Jason.decode(attrs["credential_subject"]) do
        Map.put(attrs, "credential_subject", decoded_value)
      else
        _ -> attrs
      end

    schema_version
    |> cast(attrs, [
      :description,
      :platform,
      :status,
      :credential_subject,
      :version_number,
      :user_id,
      :schema_id,
      :title
    ])
    |> Schema.validate_title()
    |> validate_description()
  end

  def validate_description(changeset) do
    changeset
    |> validate_length(:description,
      min: 2,
      max: 255,
      message: gettext("schema_description_length %{min} %{max}", min: 2, max: 255)
    )
  end

  def publish_changeset(schema_version) do
    change(schema_version, status: :published)
  end

  def archive_changeset(schema_version) do
    change(schema_version, status: :archived)
  end
end

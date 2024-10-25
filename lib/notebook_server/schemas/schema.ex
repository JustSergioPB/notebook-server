defmodule NotebookServer.Schemas.Schema do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "schemas" do
    field :title, :string
    belongs_to :org, NotebookServer.Orgs.Org
    has_many :schema_versions, NotebookServer.Schemas.SchemaVersion
    has_many :credentials, NotebookServer.Credentials.Credential

    timestamps(type: :utc_datetime)
  end

  def changeset(schema, attrs) do
    schema
    |> cast(attrs, [
      :title,
      :org_id
    ])
    |> validate_title()
  end

  def validate_title(changeset) do
    changeset
    |> validate_required([:title],
      message: gettext("field_required")
    )
    |> validate_length(:title,
      min: 2,
      max: 50,
      message: gettext("schema_title_length %{min} %{max}", min: 2, max: 50)
    )
  end
end

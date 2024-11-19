defmodule NotebookServer.Schemas.Schema do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "schemas" do
    field :title, :string
    field :public_id, :binary_id
    belongs_to :org, NotebookServer.Orgs.Org
    has_many :schema_versions, NotebookServer.Schemas.SchemaVersion

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

  def map_to_row(schema) do
    latest_version =
      schema.schema_versions
      |> Enum.take(-1)
      |> Enum.at(0)

    published_version =
      schema.schema_versions |> Enum.find(fn version -> version.status == :published end)

    published_version_number =
      if !is_nil(published_version), do: published_version.version_number, else: nil

    Map.merge(schema, %{
      description: latest_version.description,
      org_name: schema.org.name,
      version_number: latest_version.version_number,
      published_version_number: published_version_number,
      platform: latest_version.platform,
      status: latest_version.status,
      latest_version_id: latest_version.id
    })
  end
end

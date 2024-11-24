defmodule NotebookServer.Schemas.SchemaVersion do
  use Ecto.Schema
  import Ecto.Changeset

  #TODO create index with version and schema_id, to avoid having two versions with the same version number

  schema "schema_versions" do
    field :description, :string
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    embeds_one :content, NotebookServer.Schemas.SchemaContent, on_replace: :update
    field :version, :integer, default: 0
    field :public_id, :binary_id
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  def changeset(schema_version, attrs \\ %{}) do
    schema_version
    |> cast(attrs, [
      :description,
      :platform,
      :status,
      :version,
      :public_id,
      :user_id,
      :schema_id
    ])
    |> validate_required([:version, :public_id, :user_id])
    |> validate_length(:description, min: 2, max: 255)
    |> cast_embed(:content, required: true)
  end

  def publish_changeset(schema_version) do
    change(schema_version, status: :published)
  end

  def archive_changeset(schema_version) do
    change(schema_version, status: :archived)
  end
end

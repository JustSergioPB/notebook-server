defmodule NotebookServer.Schemas.SchemaVersion do
  use Ecto.Schema
  import Ecto.Changeset

  # TODO create index with version and schema_id, to avoid having two versions with the same version number

  schema "schema_versions" do
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :status, Ecto.Enum, values: [:draft, :published, :archived], default: :draft
    field :version, :integer, default: 0
    embeds_one :content, NotebookServer.Schemas.SchemaContent, on_replace: :update
    field :public_id, :binary_id
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :schema, NotebookServer.Schemas.Schema

    timestamps(type: :utc_datetime)
  end

  def changeset(schema_version, attrs \\ %{}) do
    schema_version
    |> cast(attrs, [
      :platform,
      :status,
      :user_id,
      :schema_id,
      :version
    ])
    |> validate_required([:user_id, :version])
    |> cast_embed(:content, required: true)
  end

  def publish_changeset(schema_version) do
    change(schema_version, status: :published)
  end

  def archive_changeset(schema_version) do
    change(schema_version, status: :archived)
  end
end

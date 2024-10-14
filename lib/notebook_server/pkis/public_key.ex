defmodule NotebookServer.PKIs.PublicKey do
  use Ecto.Schema
  import Ecto.Changeset

  schema "public_keys" do
    field :status, Ecto.Enum, values: [:revoked, :active, :rotated], default: :active
    field :key, :binary
    field :expiration_date, :utc_datetime
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :replaces, NotebookServer.PKIs.PublicKey
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(public_key, attrs) do
    public_key
    |> cast(attrs, [:key, :expiration_date, :status, :user_id, :org_id, :replaces_id])
    |> validate_required([:key, :expiration_date, :user_id, :org_id])
  end

  def revoke_changeset(public_key) do
    public_key
    |> change(status: :revoked)
  end

  def rotate_changeset(public_key) do
    public_key
    |> change(status: :rotated)
  end
end

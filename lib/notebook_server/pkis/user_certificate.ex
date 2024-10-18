defmodule NotebookServer.PKIs.UserCertificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_certificates" do
    field :status, Ecto.Enum, values: [:revoked, :active, :rotated], default: :active
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :revocation_reason, :string
    field :revocation_date, :utc_datetime
    field :expiration_date, :utc_datetime
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :replaces, NotebookServer.PKIs.UserCertificate
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_certificate, attrs) do
    user_certificate
    |> cast(attrs, [
      :status,
      :platform,
      :revocation_reason,
      :revocation_date,
      :expiration_date,
      :user_id,
      :org_id,
      :replaces_id
    ])
    |> validate_required([
      :expiration_date,
      :user_id,
      :org_id
    ])
  end

  def revoke_changeset(user_certificate, attrs) do
    user_certificate
    |> cast(attrs, [:revocation_reason, :revocation_date])
    |> validate_required([:revocation_reason, :revocation_date])
    |> change(status: :revoked)
  end

  def rotate_changeset(user_certificate) do
    user_certificate
    |> change(status: :rotated)
  end
end

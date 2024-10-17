defmodule NotebookServer.PKIs.OrgCertificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "org_certificates" do
    field :level, Ecto.Enum, values: [:root, :intermediate], default: :intermediate
    field :status, Ecto.Enum, values: [:revoked, :active, :rotated], default: :active
    field :cert_pem, :string
    field :public_key_pem, :string
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :revocation_reason, :string
    field :revocation_date, :utc_datetime
    field :expiration_date, :utc_datetime
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :replaces, NotebookServer.PKIs.OrgCertificate
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(org_certificate, attrs) do
    org_certificate
    |> cast(attrs, [
      :cert_pem,
      :public_key_pem,
      :level,
      :status,
      :platform,
      :expiration_date,
      :revocation_reason,
      :revocation
    ])
    |> validate_required([
      :cert_pem,
      :public_key_pem,
      :level,
      :platform,
      :expiration_date,
      :org_id
    ])
  end

  def revoke_changeset(org_certificate, attrs) do
    org_certificate
    |> cast(attrs, [:revocation_reason, :revocation_date])
    |> validate_required([:revocation_reason, :revocation_date])
    |> change(status: :revoked)
  end

  def rotate_changeset(org_certificate) do
    org_certificate
    |> change(status: :rotated)
  end
end

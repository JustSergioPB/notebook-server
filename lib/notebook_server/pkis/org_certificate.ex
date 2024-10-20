defmodule NotebookServer.PKIs.OrgCertificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "org_certificates" do
    field :uuid, :string
    field :level, Ecto.Enum, values: [:root, :intermediate], default: :intermediate
    field :status, Ecto.Enum, values: [:revoked, :active, :rotated], default: :active
    field :platform, Ecto.Enum, values: [:web2, :web3], default: :web2
    field :revocation_reason, :string
    field :revocation_date, :utc_datetime
    field :expiration_date, :utc_datetime
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :replaces, NotebookServer.PKIs.OrgCertificate
    belongs_to :issued_by, NotebookServer.PKIs.OrgCertificate
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(org_certificate, attrs) do
    org_certificate
    |> cast(attrs, [
      :uuid,
      :level,
      :status,
      :platform,
      :revocation_reason,
      :revocation_date,
      :expiration_date,
      :org_id,
      :replaces_id,
      :issued_by_id
    ])
    |> validate_required([
      :expiration_date,
      :org_id,
      :uuid
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

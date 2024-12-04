defmodule NotebookServer.Certificates.Certificate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "certificates" do
    field :public_id, :binary_id
    field :status, Ecto.Enum, values: [:revoked, :active, :rotated], default: :active
    field :level, Ecto.Enum, values: [:entity, :intermediate, :root], default: :entity
    field :public_key_pem, :string
    field :cert_pem, :string
    field :private_key_pem, :string, virtual: true, redact: true
    field :revocation_reason, :string
    field :revocation_date, :utc_datetime
    field :expiration_date, :utc_datetime

    has_one :user_certificate, NotebookServer.Certificates.UserCertificate
    has_one :org_certificate, NotebookServer.Certificates.OrgCertificate
    belongs_to :issued_by, NotebookServer.Certificates.Certificate
    belongs_to :replaces, NotebookServer.Certificates.Certificate

    timestamps(type: :utc_datetime)
  end

  def changeset(certificate, attrs) do
    certificate
    |> cast(attrs, [
      :public_id,
      :status,
      :level,
      :cert_pem,
      :public_key_pem,
      :revocation_reason,
      :revocation_date,
      :expiration_date,
      :issued_by_id,
      :replaces_id
    ])
    |> validate_required([:expiration_date, :public_key_pem, :cert_pem])
  end

  def rotate_changeset(certificate) do
    certificate
    |> change(status: :rotated)
  end

  def revoke_changeset(certificate, attrs) do
    certificate
    |> cast(attrs, [:revocation_reason, :revocation_date])
    |> validate_required([:revocation_reason, :revocation_date])
    |> change(status: :revoked)
  end
end

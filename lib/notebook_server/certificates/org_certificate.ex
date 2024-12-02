defmodule NotebookServer.Certificates.OrgCertificate do
  use Ecto.Schema
  import Ecto.Changeset
  alias NotebookServer.Certificates.Certificate

  schema "org_certificates" do
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :certificate, Certificate

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(org_certificate, attrs \\ %{}) do
    org_certificate
    |> cast(attrs, [:org_id])
    |> validate_required([:org_id])
    |> cast_assoc(:certificate, required: true)
  end
end

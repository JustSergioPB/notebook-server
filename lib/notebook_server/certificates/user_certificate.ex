defmodule NotebookServer.Certificates.UserCertificate do
  use Ecto.Schema
  use Gettext, backend: NotebookServerWeb.Gettext
  import Ecto.Changeset
  alias NotebookServer.Certificates.Certificate

  schema "user_certificates" do
    belongs_to :user, NotebookServer.Accounts.User
    belongs_to :org, NotebookServer.Orgs.Org
    belongs_to :certificate, Certificate

    timestamps(type: :utc_datetime)
  end

  def changeset(user_certificate, attrs) do
    user_certificate
    |> cast(attrs, [:org_id, :user_id])
    |> validate_required([:org_id, :user_id])
    |> cast_assoc(:certificate, required: true)
  end
end

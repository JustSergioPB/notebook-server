defmodule NotebookServer.Credentials.CredentialProof do
  import Ecto.Changeset
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field :type, :string, default: "DataIntegrityProof"
    field :cryptosuite, :string, default: "eddsa-jcs-2022"
    field :created, :utc_datetime
    field :verification_method, :string
    field :proof_purpose, :string, default: "assertionMethod"
    field :proof_value, :string
  end

  def changeset(credential_proof, attrs \\ %{}) do
    credential_proof
    |> cast(attrs, [:type, :created, :verification_method, :proof_purpose, :proof_value])
    |> validate_required([:type, :verification_method, :proof_purpose, :proof_value])
  end
end

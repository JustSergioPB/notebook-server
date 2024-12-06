defmodule NotebookServer.Credentials do
  @moduledoc """
  The Credentials context.
  """
  alias NotebookServer.Certificates
  alias NotebookServer.Repo
  alias NotebookServer.Credentials.Credential
  alias NotebookServer.Credentials.UserCredential
  alias NotebookServer.Credentials.OrgCredential
  alias NotebookServer.Orgs.Org
  alias NotebookServer.Schemas.SchemaVersion
  alias NotebookServer.Accounts.User
  alias NotebookServer.Certificates.Certificate
  import Ecto.Query, warn: false

  @doc """
  Returns the list of credentials.

  ## Examples

      iex> list_credentials()
      [%Credential{}, ...]

  """
  def list_credentials(term, opts \\ [])

  def list_credentials(:user, opts) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if !is_nil(org_id),
        do: from(u in UserCredential, where: u.org_id == ^org_id),
        else: from(u in UserCredential)

    Repo.all(query) |> Repo.preload([:user, :org, credential: [schema_version: [:schema]]])
  end

  def list_credentials(:org, opts) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if !is_nil(org_id),
        do: from(o in OrgCredential, where: o.org_id == ^org_id),
        else: from(o in OrgCredential)

    Repo.all(query) |> Repo.preload([:org, credential: [schema_version: [:schema]]])
  end

  @doc """
  Gets a single credential.

  Raises `Ecto.NoResultsError` if the Credential does not exist.

  ## Examples

      iex> get_credential!(123)
      %Credential{}

      iex> get_credential!(456)
      ** (Ecto.NoResultsError)

  """
  def get_credential!(:user, id),
    do:
      Repo.get!(UserCredential, id)
      |> Repo.preload([:user, :org, credential: [schema_version: [:schema]]])

  def get_credential!(:org, id),
    do:
      Repo.get!(OrgCredential, id)
      |> Repo.preload([:org, credential: [schema_version: [:schema]]])

  @doc """
  Creates a credential.

  ## Examples

      iex> create_credential(%{field: value})
      {:ok, %Credential{}}

      iex> create_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_credential(term, attrs \\ %{})

  def create_credential(:user, attrs) do
    %UserCredential{}
    |> UserCredential.changeset(attrs)
    |> Repo.insert()
  end

  def create_credential(:org, attrs) do
    %OrgCredential{}
    |> OrgCredential.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a credential.

  ## Examples

      iex> update_credential(credential, %{field: new_value})
      {:ok, %Credential{}}

      iex> update_credential(credential, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_credential(%Credential{} = credential, attrs) do
    credential
    |> Credential.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a credential.

  ## Examples

      iex> delete_credential(credential)
      {:ok, %Credential{}}

      iex> delete_credential(credential)
      {:error, %Ecto.Changeset{}}

  """
  def delete_credential(%Credential{} = credential) do
    Repo.delete(credential)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking credential changes.

  ## Examples

      iex> change_credential(credential)
      %Ecto.Changeset{data: %Credential{}}

  """

  def change_credential(term, credential, attrs \\ %{})

  def change_credential(:user, user_credential, attrs) do
    user_credential
    |> UserCredential.changeset(attrs)
  end

  def change_credential(:org, org_credential, attrs) do
    org_credential
    |> OrgCredential.changeset(attrs)
  end

  def complete_credential(:org, content, %Org{} = org, %SchemaVersion{} = schema_version) do
    certificate = Certificates.get_issuer_certificate!(:org, org.id, :entity)

    %{
      "org_id" => org.id,
      "credential" => complete_credential(org.public_id, content, schema_version, certificate)
    }
  end

  def complete_credential(
        :user,
        content,
        %User{} = user,
        %SchemaVersion{} = schema_version
      ) do
    certificate = Certificates.get_issuer_certificate!(:user, user.id)

    %{
      "user_id" => user.id,
      "org_id" => user.org_id,
      "credential" => complete_credential(user.public_id, content, schema_version, certificate)
    }
  end

  def complete_credential(
        issuer_public_id,
        content,
        %SchemaVersion{} = schema_version,
        %Certificate{} = certificate
      ) do
    domain_url = NotebookServerWeb.Endpoint.url()

    proof = %{
      "type" => "DataIntegrityProof",
      "cryptosuite" => "ecdsa-jcs-2022",
      "created" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "verificationMethod" => "#{domain_url}/#{issuer_public_id}/public-key",
      "proofPurpose" => "assertionMethod"
    }

    credential = %{
      "@context" => ["https://www.w3.org/ns/credentials/v2"],
      "type" => ["VerifiableCredential"],
      "title" => schema_version.schema.title,
      "issuer" => "#{domain_url}/#{issuer_public_id}",
      "credentialSubject" => %{
        "id" => "#TODO",
        "content" => content
      },
      "credentialSchema" => %{
        "id" => "#{domain_url}/schema-versions/#{schema_version.id}",
        "type" => "JsonSchema"
      },
      "proof" => proof
    }

    description = Map.get(schema_version.content, "description")

    credential =
      if is_binary(description),
        do: credential |> Map.put("description", description),
        else: credential

    canonical_form = Jcs.encode(credential)

    proof_value =
      certificate.private_key_pem
      |> X509.PrivateKey.to_pem()
      |> JOSE.JWK.from_pem()
      |> JOSE.JWS.sign(canonical_form, %{"alg" => "EdDSA"})
      |> JOSE.JWS.compact()
      |> elem(1)

    signed_proof = Map.put(proof, "proofValue", proof_value)
    credential = Map.put(credential, "proof", signed_proof)

    schema_version_id =
      if is_binary(schema_version.id),
        do: String.to_integer(schema_version.id),
        else: schema_version.id

    %{
      "schema_version_id" => schema_version_id,
      "content" => credential
    }
  end
end

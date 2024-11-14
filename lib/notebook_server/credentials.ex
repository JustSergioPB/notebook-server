defmodule NotebookServer.Credentials do
  @moduledoc """
  The Credentials context.
  """

  import Ecto.Query, warn: false
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Repo
  alias NotebookServer.Credentials.Credential
  alias NotebookServer.Credentials.UserCredential
  alias NotebookServer.Credentials.OrgCredential

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
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :create_user_credential,
      UserCredential.changeset(%UserCredential{}, attrs)
    )
    # |> Ecto.Multi.run(:create_qr, fn _repo, %{create_user_credential: user_credential} ->
    #  generate_qr(user_credential.credential)
    # end)
    |> Repo.transaction()
    |> case do
      {:ok,
       %{
         # create_qr: _,
         create_user_credential: user_credential
       }} ->
        {:ok, user_credential, gettext("credential_creation_succeded")}

      {:error, :create_user_credential, _, _} ->
        {:error, gettext("credential_creation_failed")}

      {:error, :create_qr, _, _} ->
        {:error, gettext("QR_creation_failed")}
    end
  end

  def create_credential(:org, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_org_credential, OrgCredential.changeset(%OrgCredential{}, attrs))
    |> Ecto.Multi.run(:create_qr, fn _repo, %{create_org_credential: org_credential} ->
      generate_qr(org_credential.credential)
    end)
    |> Repo.transaction()
    |> case do
      {:ok,
       %{
         create_org_credential: org_credential
         # create_qr: _
       }} ->
        {:ok, org_credential.credential, gettext("credential_creation_succeded")}

      {:error, :create_org_credential, _, _} ->
        {:error, gettext("org_credential_creation_failed")}

      {:error, :create_qr, _, _} ->
        {:error, gettext("QR_creation_failed")}
    end
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
  def delete_credential(:user, %UserCredential{} = user_credential) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete_user_credential, user_credential)
    |> Ecto.Multi.delete(:delete_credential, user_credential.credential)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, gettext("user_credential_deletion_succeed")}
      {:error, :delete_user_credential} -> {:error, gettext("user_credential_deletion_failed")}
      {:error, :delete_credential} -> {:error, gettext("credential_deletion_succeed")}
    end
  end

  def delete_credential(:org, %OrgCredential{} = org_credential) do
    Ecto.Multi.new()
    |> Ecto.Multi.delete(:delete_org_credential, org_credential)
    |> Ecto.Multi.delete(:delete_credential, org_credential.credential)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, gettext("org_credential_deletion_succeed")}
      {:error, :delete_user_credential} -> {:error, gettext("org_credential_deletion_failed")}
      {:error, :delete_credential} -> {:error, gettext("credential_deletion_succeed")}
    end
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

  defp generate_qr(credential) do
    File.mkdir_p!("./priv/static/qrs")

    credential.content
    |> Jason.encode!()
    |> QRCode.create(:high)
    |> QRCode.render()
    |> QRCode.save("./priv/static/qrs/#{credential.public_id}-qr.svg")
  end
end

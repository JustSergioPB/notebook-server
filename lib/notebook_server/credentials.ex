defmodule NotebookServer.Credentials do
  @moduledoc """
  The Credentials context.
  """

  import Ecto.Query, warn: false
  alias NotebookServer.Repo

  alias NotebookServer.Credentials.Credential

  @doc """
  Returns the list of credentials.

  ## Examples

      iex> list_credentials()
      [%Credential{}, ...]

  """
  def list_credentials(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if !is_nil(org_id),
        do: from(c in Credential, where: c.org_id == ^org_id),
        else: from(c in Credential)

    Repo.all(query) |> Repo.preload([:org, :schema, :schema_version, :issuer])
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
  def get_credential!(id), do: Repo.get!(Credential, id)

  @doc """
  Creates a credential.

  ## Examples

      iex> create_credential(%{field: value})
      {:ok, %Credential{}}

      iex> create_credential(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_credential(attrs \\ %{}, schema) do
    %Credential{}
    |> Credential.changeset(attrs, schema)
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
  def update_credential(%Credential{} = credential, attrs, schema) do
    credential
    |> Credential.changeset(attrs, schema)
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
  def change_credential(%Credential{} = credential, attrs \\ %{}, schema_version) do
    Credential.changeset(credential, attrs, schema_version)
  end
end

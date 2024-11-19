defmodule NotebookServer.Orgs do
  import Ecto.Query, warn: false
  alias NotebookServer.Repo
  alias NotebookServer.Orgs.Org
  alias NotebookServer.Accounts

  @doc """
  Returns the list of orgs.

  ## Examples

      iex> list_orgs()
      [%Org{}, ...]

  """
  def list_orgs(opts \\ []) do
    name = Keyword.get(opts, :name)

    query =
      if is_binary(name),
        do: from(o in Org, where: ilike(o.name, ^"%#{name}%")),
        else: from(o in Org)

    Repo.all(query)
  end

  @doc """
  Gets a single org.

  Raises `Ecto.NoResultsError` if the Org does not exist.

  ## Examples

      iex> get_org!(123)
      %Org{}

      iex> get_org!(456)
      ** (Ecto.NoResultsError)

  """
  def get_org!(id), do: Repo.get!(Org, id)

  @doc """
  Creates a org.

  ## Examples

      iex> create_org(%{field: value})
      {:ok, %Org{}}

      iex> create_org(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_org(attrs \\ %{}, opts \\ []) do
    %Org{}
    |> Org.changeset(attrs, opts)
    |> Repo.insert()
  end

  def register_org(attrs \\ %{}, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    zero = attrs |> get_in(["users", "0"]) |> Map.put("role", :org_admin)
    attrs = attrs |> Map.put("users", %{"0" => zero})

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:create_org, Org.changeset(%Org{}, attrs, user: true))
    |> Ecto.Multi.run(:deliver_mail, fn _, %{create_org: org} ->
      user = org |> Map.get(:users) |> Enum.at(0)

      Accounts.deliver_user_confirmation_instructions(
        user,
        confirmation_url_fun
      )
      |> case do
        {:ok, _} -> {:ok, nil}
        {:error, _} -> {:error, nil}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_org: org}} ->
        {:ok, org}

      {:error, :create_org, changeset, _} ->
        {:error, changeset, :create_org}

      {:error, :deliver_mail, _, _} ->
        {:error, :deliver_mail}
    end
  end

  @doc """
  Updates a org.

  ## Examples

      iex> update_org(org, %{field: new_value})
      {:ok, %Org{}}

      iex> update_org(org, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_org(%Org{} = org, attrs) do
    org
    |> Org.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a org.

  ## Examples

      iex> delete_org(org)
      {:ok, %Org{}}

      iex> delete_org(org)
      {:error, %Ecto.Changeset{}}

  """
  def delete_org(%Org{} = org) do
    Repo.delete(org)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking org changes.

  ## Examples

      iex> change_org(org)
      %Ecto.Changeset{data: %Org{}}

  """
  def change_org(%Org{} = org, attrs \\ %{}, opts \\ []) do
    Org.changeset(org, attrs, opts)
  end

  def deactivate_org(%Org{} = org) do
    org
    |> Org.deactivation_changeset()
    |> Repo.update()
  end

  def activate_org(%Org{} = org) do
    org
    |> Org.activation_changeset()
    |> Repo.update()
  end

  def ban_org(%Org{} = org) do
    org
    |> Org.ban_changeset()
    |> Repo.update()
  end

  def get_org_by_public_id!(public_id),
    do: Repo.get_by!(Org, public_id: public_id)
end

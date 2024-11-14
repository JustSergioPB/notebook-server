defmodule NotebookServer.Bridges do
  @moduledoc """
  The Bridges context.
  """

  import Ecto.Query, warn: false
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Bridges.EmailEvidenceBridgeNotifier
  alias NotebookServer.Bridges.EmailEvidenceBridge
  alias NotebookServer.Bridges.EvidenceBridge
  alias NotebookServer.Bridges.Bridge
  alias NotebookServer.Repo

  @doc """
  Returns the list of bridges.

  ## Examples

      iex> list_bridges()
      [%Bridge{}, ...]

  """
  def list_bridges(opts \\ []) do
    tag = Keyword.get(opts, :tag)

    query =
      if is_binary(tag),
        do: from(b in Bridge, where: ilike(b.tag, ^"%#{tag}%")),
        else: from(b in Bridge)

    Repo.all(query)
  end

  @doc """
  Gets a single bridge.

  Raises `Ecto.NoResultsError` if the Bridge does not exist.

  ## Examples

      iex> get_bridge!(123)
      %Bridge{}

      iex> get_bridge!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bridge!(id), do: Repo.get!(Bridge, id)

  @doc """
  Creates a bridge.

  ## Examples

      iex> create_bridge(%{field: value})
      {:ok, %Bridge{}}

      iex> create_bridge(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bridge(attrs \\ %{}) do
    %Bridge{}
    |> Bridge.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a bridge.

  ## Examples

      iex> update_bridge(bridge, %{field: new_value})
      {:ok, %Bridge{}}

      iex> update_bridge(bridge, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bridge(%Bridge{} = bridge, attrs) do
    bridge
    |> Bridge.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bridge.

  ## Examples

      iex> delete_bridge(bridge)
      {:ok, %Bridge{}}

      iex> delete_bridge(bridge)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bridge(%Bridge{} = bridge) do
    Repo.delete(bridge)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bridge changes.

  ## Examples

      iex> change_bridge(bridge)
      %Ecto.Changeset{data: %Bridge{}}

  """
  def change_bridge(%Bridge{} = bridge, attrs \\ %{}) do
    Bridge.changeset(bridge, attrs)
  end

  def create_evidence_bridge(attrs \\ %{}) do
    %EvidenceBridge{}
    |> EvidenceBridge.changeset(attrs)
    |> Repo.insert()
  end

  def update_evidence_bridge(%EvidenceBridge{} = evidence_bridge, attrs) do
    evidence_bridge
    |> EvidenceBridge.changeset(attrs)
    |> Repo.update()
  end

  def get_evidence_bridge!(id),
    do: Repo.get!(EvidenceBridge, id) |> Repo.preload([:org, :bridge, schema: [:schema_versions]])

  def get_evidence_bridge_by_public_id!(public_id),
    do:
      Repo.get_by!(EvidenceBridge, public_id: public_id)
      |> Repo.preload([:org, :bridge, schema: [:schema_versions]])

  def list_evidence_bridges(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)

    query =
      if !is_nil(org_id),
        do: from(o in EvidenceBridge, where: o.org_id == ^org_id),
        else: from(o in EvidenceBridge)

    Repo.all(query) |> Repo.preload([:org, :bridge, schema: [:schema_versions]])
  end

  def delete_evidence_bridge(%EvidenceBridge{} = evidence_bridge) do
    Repo.delete(evidence_bridge)
  end

  def change_evidence_bridge(%EvidenceBridge{} = evidence_bridge, attrs \\ %{}) do
    EvidenceBridge.changeset(evidence_bridge, attrs)
  end

  def create_email_evidence_bridge(attrs \\ %{}) do
    code = Enum.random(100_000..999_999)
    attrs = attrs |> Map.put("code", code)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :create_email_evidence_bridge,
      EmailEvidenceBridge.changeset(%EmailEvidenceBridge{}, attrs)
    )
    |> Ecto.Multi.run(:deliver_mail, fn _, %{create_email_evidence_bridge: email_bridge} ->
      email = email_bridge |> Map.get(:email)
      code = email_bridge |> Map.get(:code)
      EmailEvidenceBridgeNotifier.deliver_code(email, code)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_email_evidence_bridge: email_bridge, deliver_mail: _}} ->
        {:ok, email_bridge, gettext("email_code_delivery_succeeded")}

      {:error, :create_email_evidence_bridge, _, _} ->
        {:error, gettext("email_bridge_creation_failed")}

      {:error, :deliver_mail, _, _} ->
        {:error, gettext("email_code_delivery_failed")}
    end
  end

  def validate_email_evidence_bridge(%EmailEvidenceBridge{} = email_evidence_bridge) do
    id = email_evidence_bridge |> Map.get(:id)
    code = email_evidence_bridge |> Map.get(:code)

    Ecto.Multi.new()
    |> Ecto.Multi.one(
      :find_email_evidence_bridge,
      from(eb in EmailEvidenceBridge,
        where: eb.id == ^id
      )
    )
    |> Ecto.Multi.run(
      :check_code,
      fn _repo, %{find_email_evidence_bridge: email_evidence_bridge} ->
        if !is_nil(email_evidence_bridge) &&
             email_evidence_bridge.code == String.to_integer(code),
           do: {:ok, nil},
           else: {:error, nil}
      end
    )
    |> Ecto.Multi.update(
      :update_email_evidence_bridge,
      fn %{find_email_evidence_bridge: email_evidence_bridge} ->
        EmailEvidenceBridge.validate_changeset(email_evidence_bridge)
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{find_email_evidence_bridge: email_evidence_bridge, update_email_evidence_bridge: _}} ->
        {:ok, email_evidence_bridge, gettext("credential_creation_succeeded")}

      {:error, :find_email_evidence_bridge, _, _} ->
        {:error, gettext("email_evidence_bridge_search_failed")}

      {:error, :check_code, _, _} ->
        {:error, gettext("email_evidence_bridge_check_failed")}

      {:error, :update_email_evidence_bridge, _, _} ->
        {:error, gettext("email_evidence_bridge_update_failed")}
    end
  end

  def change_email_evidence_bridge(%EmailEvidenceBridge{} = email_evidence_bridge, attrs \\ %{}) do
    EmailEvidenceBridge.changeset(email_evidence_bridge, attrs)
  end
end

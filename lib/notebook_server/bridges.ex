defmodule NotebookServer.Bridges do
  @moduledoc """
  The Bridges context.
  """

  import Ecto.Query, warn: false
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Bridges.EmailBridgeNotifier
  alias NotebookServer.Bridges.EmailBridge
  alias NotebookServer.Bridges.Bridge
  alias NotebookServer.Repo

  def create_bridge(attrs \\ %{}) do
    %Bridge{}
    |> Bridge.changeset(attrs)
    |> Repo.insert()
  end

  def update_bridge(%Bridge{} = bridge, attrs) do
    bridge
    |> Bridge.changeset(attrs)
    |> Repo.update()
  end

  def get_bridge!(id),
    do: Repo.get!(Bridge, id) |> Repo.preload([:org, schema: [:schema_versions]])

  def get_bridge_by_public_id!(public_id),
    do:
      Repo.get_by!(Bridge, public_id: public_id)
      |> Repo.preload([:org, schema: [:schema_versions]])

  def list_bridges(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)
    active = Keyword.get(opts, :active)

    query =
      if !is_nil(org_id),
        do: from(o in Bridge, where: o.org_id == ^org_id),
        else: from(o in Bridge)

    query =
      if is_boolean(active),
        do: from(o in query, where: o.active == ^active),
        else: from(o in query)

    Repo.all(query) |> Repo.preload([:org, schema: [:schema_versions]])
  end

  def delete_bridge(%Bridge{} = bridge) do
    Repo.delete(bridge)
  end

  def change_bridge(%Bridge{} = bridge, attrs \\ %{}) do
    Bridge.changeset(bridge, attrs)
  end

  def create_email_bridge(attrs \\ %{}) do
    code = Enum.random(100_000..999_999)
    attrs = attrs |> Map.put("code", code)

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :create_email_bridge,
      EmailBridge.changeset(%EmailBridge{}, attrs)
    )
    |> Ecto.Multi.run(:deliver_mail, fn _, %{create_email_bridge: email_bridge} ->
      email = email_bridge |> Map.get(:email)
      code = email_bridge |> Map.get(:code)
      EmailBridgeNotifier.deliver_code(email, code)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{create_email_bridge: email_bridge, deliver_mail: _}} ->
        {:ok, email_bridge, dgettext("email_bridges", "code_delivery_succeeded")}

      {:error, :create_email_bridge, _, _} ->
        {:error, dgettext("email_bridges", "creation_failed")}

      {:error, :deliver_mail, _, _} ->
        {:error, dgettext("email_bridges", "code_delivery_failed")}
    end
  end

  def validate_email_bridge(%EmailBridge{} = email_bridge) do
    id = email_bridge |> Map.get(:id)
    code = email_bridge |> Map.get(:code)

    Ecto.Multi.new()
    |> Ecto.Multi.one(
      :find_email_bridge,
      from(eb in EmailBridge,
        where: eb.id == ^id
      )
    )
    |> Ecto.Multi.run(
      :check_code,
      fn _repo, %{find_email_bridge: email_bridge} ->
        if !is_nil(email_bridge) &&
             email_bridge.code == String.to_integer(code),
           do: {:ok, nil},
           else: {:error, nil}
      end
    )
    |> Ecto.Multi.update(
      :update_email_bridge,
      fn %{find_email_bridge: email_bridge} ->
        EmailBridge.validate_changeset(email_bridge)
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{find_email_bridge: email_bridge, update_email_bridge: _}} ->
        {:ok, email_bridge, dgettext("email_bridges", "credential_creation_succeeded")}

      {:error, :find_email_bridge, _, _} ->
        {:error, dgettext("email_bridges", "search_failed")}

      {:error, :check_code, _, _} ->
        {:error, dgettext("email_bridges", "check_failed")}

      {:error, :update_email_bridge, _, _} ->
        {:error, dgettext("email_bridges", "update_failed")}
    end
  end

  def change_email_bridge(%EmailBridge{} = email_bridge, attrs \\ %{}) do
    EmailBridge.changeset(email_bridge, attrs)
  end
end

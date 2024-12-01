defmodule NotebookServer.Bridges do
  @moduledoc """
  The Bridges context.
  """

  import Ecto.Query, warn: false
  alias NotebookServer.Schemas
  alias NotebookServer.Bridges.EmailBridgeNotifier
  alias NotebookServer.Bridges.EmailBridge
  alias NotebookServer.Bridges.Bridge
  alias NotebookServer.Schemas.SchemaVersion
  alias NotebookServer.Repo

  def create_bridge(attrs \\ %{}) do
    %Bridge{}
    |> Bridge.changeset(attrs)
    |> Repo.insert()
  end

  # TODO Fix this
  def update_bridge(%Bridge{} = bridge, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:update_bridge, Bridge.changeset(bridge, attrs, create: false))
    |> Ecto.Multi.run(:update_schema, fn _, _ ->
      schema_attrs = attrs |> Map.get("schema")
      Schemas.update_schema(bridge.schema, schema_attrs)
    end)
    |> Repo.transaction()
  end

  def toggle_bridge(%Bridge{} = bridge) do
    bridge |> Bridge.changeset(%{"active" => !bridge.active}, create: false) |> Repo.update()
  end

  def get_bridge!(id),
    do:
      Repo.get!(Bridge, id)
      |> Repo.preload([
        :org,
        schema: [
          schema_versions: from(sv in SchemaVersion, order_by: [desc: sv.version], limit: 1)
        ]
      ])

  def get_bridge_by_public_id!(public_id),
    do:
      Repo.get_by!(Bridge, public_id: public_id)
      |> Repo.preload([
        :org,
        schema: [
          schema_versions: from(sv in SchemaVersion, order_by: [desc: sv.version], limit: 1)
        ]
      ])

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

    Repo.all(query)
    |> Repo.preload([
      :org,
      schema: [schema_versions: from(sv in SchemaVersion, order_by: [desc: sv.version], limit: 1)]
    ])
  end

  def delete_bridge(%Bridge{} = bridge) do
    Repo.delete(bridge)
  end

  def change_bridge(%Bridge{} = bridge, attrs \\ %{}) do
    Bridge.changeset(bridge, attrs)
  end

  def create_email_bridge(attrs \\ %{}) do
    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :create_email_bridge,
      EmailBridge.changeset(%EmailBridge{}, attrs)
    )
    |> Ecto.Multi.run(:deliver_mail, fn _, %{create_email_bridge: email_bridge} ->
      EmailBridgeNotifier.deliver_code(email_bridge.email, email_bridge.code)
    end)
    |> Repo.transaction()
  end

  def get_email_bridge!(id),
    do: Repo.get!(EmailBridge, id) |> Repo.preload(org_credential: [:credential])

  def validate_email_bridge(%EmailBridge{} = email_bridge, attrs \\ %{}) do
    email_bridge |> EmailBridge.changeset(attrs, create: true) |> Repo.update()
  end

  def change_email_bridge(%EmailBridge{} = email_bridge, attrs \\ %{}) do
    EmailBridge.changeset(email_bridge, attrs)
  end
end

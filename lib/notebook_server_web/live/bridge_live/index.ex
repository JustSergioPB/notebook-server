defmodule NotebookServerWeb.BridgeLive.Index do
  alias NotebookServer.Bridges
  alias NotebookServer.Bridges.Bridge
  alias NotebookServer.Orgs
  alias NotebookServer.Schemas
  alias NotebookServer.Schemas.Schema
  alias NotebookServer.Schemas.SchemaVersion
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :bridges, Bridges.list_bridges(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, dgettext("bridges", "edit"))
    |> assign(:bridge, Bridges.get_bridge!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, dgettext("bridges", "new"))
    |> assign(:bridge, %Bridge{
      type: :email,
      schema: %Schema{schema_versions: [%SchemaVersion{platform: :web2}]}
    })
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, dgettext("bridges", "bridges"))
    |> assign(:bridge, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.BridgeLive.FormComponent, {:saved, bridge}},
        socket
      ) do
    refresh_row(bridge, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bridge = Bridges.get_bridge!(id)
    {:ok, _} = Bridges.delete_bridge(bridge)

    {:noreply, stream_delete(socket, :bridges, bridge)}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    bridge = Bridges.get_bridge!(id)

    case Bridges.update_bridge(bridge, %{active: !bridge.active}) do
      {:ok, bridge} ->
        refresh_row(bridge, socket)

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end

  defp refresh_row(bridge, socket) do
    org = Orgs.get_org!(bridge.org_id)
    schema = Schemas.get_schema!(bridge.schema_id)
    bridge = Bridges.get_bridge!(bridge.bridge_id)
    bridge = bridge |> Map.merge(%{org: org, schema: schema, bridge: bridge})
    {:noreply, stream_insert(socket, :bridges, bridge)}
  end
end

defmodule NotebookServerWeb.EvidenceBridgeLive.Index do
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Bridges.EvidenceBridge
  alias NotebookServer.Accounts.User
  alias NotebookServer.Bridges
  alias NotebookServer.Orgs
  alias NotebookServer.Schemas

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :evidence_bridges, Bridges.list_evidence_bridges(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("edit_evidence_bridge"))
    |> assign(:evidence_bridge, Bridges.get_evidence_bridge!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_evidence_bridge"))
    |> assign(:evidence_bridge, %EvidenceBridge{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("evidence_bridges"))
    |> assign(:evidence_bridge, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.EvidenceBridgeLive.FormComponent, {:saved, evidence_bridge}},
        socket
      ) do
    refresh_row(evidence_bridge, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    evidence_bridge = Bridges.get_evidence_bridge!(id)
    {:ok, _} = Bridges.delete_evidence_bridge(evidence_bridge)

    {:noreply, stream_delete(socket, :evidence_bridges, evidence_bridge)}
  end

  def handle_event("toggle", %{"id" => id}, socket) do
    evidence_bridge = Bridges.get_evidence_bridge!(id)

    case Bridges.update_evidence_bridge(evidence_bridge, %{active: !evidence_bridge.active}) do
      {:ok, evidence_bridge} ->
        refresh_row(evidence_bridge, socket)

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end

  defp refresh_row(evidence_bridge, socket) do
    org = Orgs.get_org!(evidence_bridge.org_id)
    schema = Schemas.get_schema!(evidence_bridge.schema_id)
    bridge = Bridges.get_bridge!(evidence_bridge.bridge_id)
    evidence_bridge = evidence_bridge |> Map.merge(%{org: org, schema: schema, bridge: bridge})
    {:noreply, stream_insert(socket, :evidence_bridges, evidence_bridge)}
  end
end

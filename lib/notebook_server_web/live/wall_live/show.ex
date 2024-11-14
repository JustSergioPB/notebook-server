defmodule NotebookServerWeb.WallLive.Show do
  alias NotebookServer.Bridges.EvidenceBridge
  alias NotebookServer.Bridges
  alias NotebookServer.Orgs
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_user.org_id
    base_url = NotebookServerWeb.Endpoint.url()
    org = Orgs.get_org!(org_id)

    {:ok,
     socket
     |> stream(
       :evidence_bridges,
       Bridges.list_evidence_bridges(org_id: org_id)
       |> Enum.map(fn evidence_bridge -> evidence_bridge |> EvidenceBridge.map_to_wall() end)
     )
     |> assign(:url, "#{base_url}/#{org.public_id}/wall")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, gettext("wall_bridges"))
     |> assign(:active_tab, params["tab"] || "evidence_bridges")}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    evidence_bridge = Bridges.get_evidence_bridge!(id)

    case Bridges.update_evidence_bridge(evidence_bridge, %{active: !evidence_bridge.active}) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, gettext("bridge_update_success"))}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, gettext("bridge_update_failed"))}
    end
  end
end

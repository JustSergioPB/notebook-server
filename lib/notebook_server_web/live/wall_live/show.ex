defmodule NotebookServerWeb.WallLive.Show do
  alias NotebookServer.Bridges.Bridge
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
       :bridges,
       Bridges.list_bridges(org_id: org_id)
       |> Enum.map(fn bridge -> bridge |> Bridge.map_to_wall() end)
     )
     |> assign(:url, "#{base_url}/#{org.public_id}/wall")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, dgettext("orgs", "wall_title"))
     |> assign(:active_tab, params["tab"] || "bridges")}
  end

  @impl true
  def handle_event("toggle", %{"id" => id}, socket) do
    bridge = Bridges.get_bridge!(id)

    case Bridges.update_bridge(bridge, %{active: !bridge.active}) do
      {:ok, _} ->
        {:noreply, socket |> put_flash(:info, dgettext("bridges", "bridge_update_succeded"))}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, dgettext("bridges", "bridge_update_failed"))}
    end
  end
end

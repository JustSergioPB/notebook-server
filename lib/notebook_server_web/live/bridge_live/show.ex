defmodule NotebookServerWeb.BridgeLive.Show do
  use NotebookServerWeb, :live_view_app

  alias NotebookServer.Bridges

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:bridge, Bridges.get_bridge!(id))}
  end

  defp page_title(:show), do: "Show Bridge"
  defp page_title(:edit), do: "Edit Bridge"
end

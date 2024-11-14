defmodule NotebookServerWeb.BridgeLive.Index do
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Bridges
  alias NotebookServer.Bridges.Bridge
  alias NotebookServer.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :bridges, Bridges.list_bridges())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("edit_bridge"))
    |> assign(:bridge, Bridges.get_bridge!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_bridge"))
    |> assign(:bridge, %Bridge{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("bridges"))
    |> assign(:bridge, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.BridgeLive.FormComponent, {:saved, bridge}}, socket) do
    {:noreply, stream_insert(socket, :bridges, bridge)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    bridge = Bridges.get_bridge!(id)
    {:ok, _} = Bridges.delete_bridge(bridge)

    {:noreply, stream_delete(socket, :bridges, bridge)}
  end
end

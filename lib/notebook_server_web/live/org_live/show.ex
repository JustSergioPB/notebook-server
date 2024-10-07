defmodule NotebookServerWeb.OrgLive.Show do
  use NotebookServerWeb, :live_view

  alias NotebookServer.Orgs
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:org, Orgs.get_org!(id))}
  end

  defp page_title(:show), do: gettext("show_org")
  defp page_title(:edit), do: gettext("edit_org")
end

defmodule NotebookServerWeb.KeyLive.Show do
  use NotebookServerWeb, :live_view

  alias NotebookServer.PKIs
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
     |> assign(:key, PKIs.get_user_certificate_by_user_id(id))}
  end

  defp page_title(:show), do: gettext("show_key")
  defp page_title(:edit), do: gettext("edit_key")
end

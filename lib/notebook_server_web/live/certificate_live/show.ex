defmodule NotebookServerWeb.CertificateLive.Show do
  alias NotebookServer.Certificates
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id, "tab" => tab}, _, socket) do
    atom = tab |> String.to_atom()

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:certificate, Certificates.get_certificate!(atom, id))}
  end

  defp page_title(:show), do: dgettext("certificates", "show")
  defp page_title(:edit), do: dgettext("certificates", "edit")
end

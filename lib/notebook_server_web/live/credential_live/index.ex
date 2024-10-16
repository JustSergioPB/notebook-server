defmodule NotebookServerWeb.CredentialLive.Index do
  use NotebookServerWeb, :live_view

  alias NotebookServer.Credentials
  alias NotebookServer.Credentials.Credential
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :credentials, Credentials.list_credentials(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("edit_credential"))
    |> assign(:credential, Credentials.get_credential!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_credential"))
    |> assign(:credential, %Credential{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("credentials"))
    |> assign(:credential, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.CredentialLive.FormComponent, {:saved, credential}}, socket) do
    {:noreply, stream_insert(socket, :credentials, credential)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    credential = Credentials.get_credential!(id)
    {:ok, _} = Credentials.delete_credential(credential)

    {:noreply, stream_delete(socket, :credentials, credential)}
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

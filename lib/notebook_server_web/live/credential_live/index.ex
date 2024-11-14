defmodule NotebookServerWeb.CredentialLive.Index do
  alias NotebookServer.Credentials
  alias NotebookServer.Credentials.UserCredential
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)

    {:ok,
     socket
     |> stream(:user_credentials, Credentials.list_credentials(:user, opts))
     |> stream(:org_credentials, Credentials.list_credentials(:org, opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = if params["tab"], do: "#{params["tab"]}-credentials", else: "user-credentials"

    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:active_tab, tab)}
  end

  defp apply_action(socket, :edit, %{"id" => id, "tab" => term}) do
    atom = term |> String.to_atom()

    socket
    |> assign(:page_title, gettext("edit_credential"))
    |> assign(:credential, Credentials.get_credential!(atom, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_credential"))
    |> assign(:credential, %UserCredential{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("credentials"))
    |> assign(:credential, nil)
  end

  defp apply_action(socket, :qr, %{"id" => id, "tab" => term}) do
    atom = term |> String.to_atom()

    socket
    |> assign(:page_title, gettext("credential_qr"))
    |> assign(:credential, Credentials.get_credential!(atom, id))
  end

  @impl true
  def handle_info({NotebookServerWeb.CredentialLive.FormComponent, {:saved, credential}}, socket) do
    credential = Credentials.get_credential!(:user, credential.id)
    {:noreply, stream_insert(socket, :user_credentials, credential)}
  end

  @impl true
  def handle_event("delete", %{"id" => id, "term" => term}, socket) do
    atom = term |> String.to_atom()
    credential = Credentials.get_credential!(atom, id)
    {:ok, _} = Credentials.delete_credential(atom, credential)

    {:noreply, stream_delete(socket, :user_credentials, credential)}
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

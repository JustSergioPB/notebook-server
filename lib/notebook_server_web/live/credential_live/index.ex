defmodule NotebookServerWeb.CredentialLive.Index do
  alias NotebookServer.Credentials
  alias NotebookServer.Credentials.UserCredential
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    org_id = socket.assigns.current_user.org_id

    {:ok,
     socket
     |> stream(:user_credentials, Credentials.list_credentials(:user, org_id: org_id))
     |> stream(:org_credentials, Credentials.list_credentials(:org, org_id: org_id))}
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
    |> assign(:page_title, dgettext("credentials", "edit"))
    |> assign(:credential, Credentials.get_credential!(atom, id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, dgettext("credentials", "new"))
    |> assign(:credential, %UserCredential{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, dgettext("credentials", "credentials"))
    |> assign(:credential, nil)
  end

  defp apply_action(socket, :qr, %{"id" => id, "tab" => term}) do
    atom = term |> String.to_atom()

    socket
    |> assign(:page_title, dgettext("credentials", "qr"))
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

    case Credentials.delete_credential(credential.credential) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("credentials", "deletion_succeded"))
         |> delete_credential(atom, credential)}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("credentials", "deletion_failed"))}
    end
  end

  defp delete_credential(socket, :user, credential),
    do: socket |> stream_delete(:user_credentials, credential)

  defp delete_credential(socket, :org, credential),
    do: socket |> stream_delete(:org_credentials, credential)
end

defmodule NotebookServerWeb.CredentialLive.Index do
  alias NotebookServer.Accounts
  use NotebookServerWeb, :live_view

  alias NotebookServer.Credentials
  alias NotebookServer.Credentials.Credential
  alias NotebookServer.Accounts
  alias NotebookServer.Orgs
  alias NotebookServer.Schemas
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

  defp apply_action(socket, :qr, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("credential_qr"))
    |> assign(:credential, Credentials.get_credential!(id))
  end

  @impl true
  def handle_info({NotebookServerWeb.CredentialLive.FormComponent, {:saved, credential}}, socket) do
    user = Accounts.get_user!(credential.issuer_id)
    org = Orgs.get_org!(credential.org_id)
    schema = Schemas.get_schema!(credential.schema_id)
    schema_version = Schemas.get_schema_version!(credential.schema_version_id)

    credential =
      Map.merge(credential, %{
        issuer: user,
        org: org,
        schema: schema,
        schema_version: schema_version
      })

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

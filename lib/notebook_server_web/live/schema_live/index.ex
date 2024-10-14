defmodule NotebookServerWeb.SchemaLive.Index do
  use NotebookServerWeb, :live_view

  alias NotebookServer.Credentials
  alias NotebookServer.Credentials.Schema
  alias NotebookServer.Accounts.User
  alias NotebookServer.Orgs
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :schemas, Credentials.list_schemas(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("edit_schema"))
    |> assign(:schema, Credentials.get_schema!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_schema"))
    |> assign(:schema, %Schema{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("schemas"))
    |> assign(:schema, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.SchemaLive.FormComponent, {:saved, schema}}, socket) do
    # TODO: check if there's a better way to do this
    org = Orgs.get_org!(schema.org_id)
    schema = Map.put(schema, :org, org)
    {:noreply, stream_insert(socket, :schemas, schema)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    schema = Credentials.get_schema!(id)
    {:ok, _} = Credentials.delete_schema(schema)

    {:noreply, stream_delete(socket, :schemas, schema)}
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

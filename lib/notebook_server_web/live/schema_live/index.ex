defmodule NotebookServerWeb.SchemaLive.Index do
  alias NotebookServer.Schemas.SchemaVersion
  use NotebookServerWeb, :live_view_app

  alias NotebookServer.Schemas
  alias NotebookServer.Schemas.Schema
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)

    {:ok,
     stream(
       socket,
       :schemas,
       Schemas.list_schemas(opts)
       |> Enum.map(fn schema -> schema |> Schema.map_to_row() end)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    schema = Schemas.get_schema!(id)

    schema_version =
      schema.schema_versions
      |> Enum.take(-1)
      |> Enum.at(0)
      |> Map.merge(%{title: schema.title, org_id: schema.org_id})
      |> SchemaVersion.get_raw_content()

    socket
    |> assign(:page_title, gettext("edit_schema"))
    |> assign(:schema_version, schema_version)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_schema"))
    |> assign(:schema_version, %SchemaVersion{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("schemas"))
    |> assign(:schema_version, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.SchemaLive.FormComponent, {:saved, schema, _schema_version}},
        socket
      ) do
    schema = Schemas.get_schema!(schema.id)

    {:noreply,
     stream_insert(
       socket,
       :schemas,
       schema
       |> Schema.map_to_row()
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    schema = Schemas.get_schema!(id)
    {:ok, _} = Schemas.delete_schema(schema)

    {:noreply, stream_delete(socket, :schemas, schema)}
  end

  def handle_event("publish", %{"id" => schema_version_id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      Schemas.publish_schema_version(schema_version_id)
      |> case do
        {:ok, schema_version} ->
          {:noreply,
           stream_insert(
             socket,
             :schemas,
             Schemas.get_schema!(schema_version.schema_id) |> Schema.map_to_row()
           )}

        {:error, message} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             message
           )}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("archive", %{"id" => schema_version_id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      Schemas.archive_schema_version(schema_version_id)
      |> case do
        {:ok, schema_version} ->
          {:noreply,
           stream_insert(
             socket,
             :schemas,
             Schemas.get_schema!(schema_version.schema_id) |> Schema.map_to_row()
           )}

        {:error, message} ->
          {:noreply,
           put_flash(
             socket,
             :error,
             message
           )}
      end
    else
      {:noreply, socket}
    end
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

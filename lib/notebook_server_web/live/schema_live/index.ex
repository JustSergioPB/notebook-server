defmodule NotebookServerWeb.SchemaLive.Index do
  alias NotebookServer.Orgs
  alias NotebookServer.Schemas.SchemaVersion
  alias NotebookServer.Schemas
  alias NotebookServer.Schemas.Schema
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)

    {:ok,
     stream(
       socket,
       :schemas,
       Schemas.list_schemas(opts)
       |> Enum.map(fn schema -> map_to_row(schema) end)
     )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    schema = Schemas.get_schema!(id)

    socket
    |> assign(:page_title, dgettext("schemas", "edit"))
    |> assign(:schema, schema)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, dgettext("schemas", "new"))
    |> assign(:schema, %Schema{schema_versions: [%SchemaVersion{}]})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, dgettext("schemas", "title"))
    |> assign(:schema, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.SchemaLive.FormComponent, {:saved, schema}},
        socket
      ) do
    org = Orgs.get_org!(schema.org_id)
    schema = schema |> Map.put(:org, org)
    {:noreply, stream_insert(socket, :schemas, map_to_row(schema))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    schema = Schemas.get_schema!(id)

    case Schemas.delete_schema(schema) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("schemas", "delete_succeded"))
         |> stream_delete(:schemas, schema)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("schemas", "delete_failed"))}
    end
  end

  def handle_event("publish", %{"id" => schema_version_id}, socket) do
    schema_version = Schemas.get_schema_version!(schema_version_id)

    case Schemas.publish_schema_version(schema_version) do
      {:ok, schema_version} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("schema_versions", "publication_succeded"))
         |> stream_insert(:schemas, map_to_row(schema_version.schema))}

      {:error, _, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schema_versions", "publication_failed"))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schema_versions", "old_version_archivation_failed"))}
    end
  end

  def handle_event("archive", %{"id" => schema_version_id}, socket) do
    schema_version = Schemas.get_schema_version!(schema_version_id)

    case Schemas.archive_schema_version(schema_version) do
      {:ok, schema_version} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("schema_versions", "archivation_succeded"))
         |> stream_insert(:schemas, map_to_row(schema_version.schema))}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, dgettext("schema_versions", "archivation_failed"))}
    end
  end

  defp map_to_row(schema) do
    latest_version =
      schema.schema_versions
      |> Enum.take(-1)
      |> Enum.at(0)

    published_version =
      schema.schema_versions |> Enum.find(fn version -> version.status == :published end)

    published_version =
      if !is_nil(published_version), do: published_version.version, else: nil

    Map.merge(schema, %{
      description: latest_version.description,
      org_name: schema.org.name,
      version: latest_version.version,
      published_version: published_version,
      platform: latest_version.platform,
      status: latest_version.status,
      latest_version_id: latest_version.id
    })
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

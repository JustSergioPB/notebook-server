defmodule NotebookServerWeb.OrgLive.Index do
  use NotebookServerWeb, :live_view

  alias NotebookServer.Orgs
  alias NotebookServer.Orgs.Org
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :orgs, Orgs.list_orgs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("edit_org"))
    |> assign(:org, Orgs.get_org!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_org"))
    |> assign(:org, %Org{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("orgs"))
    |> assign(:org, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.OrgLive.FormComponent, {:saved, org}}, socket) do
    {:noreply, stream_insert(socket, :orgs, org)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org = Orgs.get_org!(id)
    {:ok, _} = Orgs.delete_org(org)

    {:noreply, stream_delete(socket, :orgs, org)}
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    org = Orgs.get_org!(id)
    {:ok, _} = Orgs.deactivate_org(org)

    {:noreply, stream(socket, :orgs, Orgs.list_orgs())}
  end

  @impl true
  def handle_event("activate", %{"id" => id}, socket) do
    org = Orgs.get_org!(id)
    {:ok, _} = Orgs.activate_org(org)

    {:noreply, stream(socket, :orgs, Orgs.list_orgs())}
  end
end

defmodule NotebookServerWeb.OrgLive.Index do
  use NotebookServerWeb, :live_view

  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.Org

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :orgs, Accounts.list_orgs())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Org")
    |> assign(:org, Accounts.get_org!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Org")
    |> assign(:org, %Org{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Orgs")
    |> assign(:org, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.OrgLive.FormComponent, {:saved, org}}, socket) do
    {:noreply, stream_insert(socket, :orgs, org)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org = Accounts.get_org!(id)
    {:ok, _} = Accounts.delete_org(org)

    {:noreply, stream_delete(socket, :orgs, org)}
  end
end

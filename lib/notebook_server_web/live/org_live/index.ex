defmodule NotebookServerWeb.OrgLive.Index do
  alias NotebookServer.Orgs
  alias NotebookServer.Orgs.Org
  use NotebookServerWeb, :live_view_app
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
    |> assign(:page_title, dgettext("orgs", "edit"))
    |> assign(:org, Orgs.get_org!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, dgettext("orgs", "new"))
    |> assign(:org, %Org{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, dgettext("orgs", "title"))
    |> assign(:org, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.OrgLive.FormComponent, {:saved, org}}, socket) do
    {:noreply, stream_insert(socket, :orgs, org)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    org = Orgs.get_org!(id)

    case Orgs.delete_org(org) do
      {:ok, org} ->
        {:noreply, stream_delete(socket, :orgs, org)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, dgettext("orgs", "org_deletion_failed"))}
    end
  end

  def handle_event("activate", %{"id" => id}, socket) do
    org = Orgs.get_org!(id)

    case Orgs.activate_org(org) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("orgs", "org_activation_succeded"))
         |> stream_insert(:orgs, org)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, dgettext("orgs", "org_activation_failed"))}
    end
  end

  def handle_event("ban", %{"id" => id}, socket) do
    org = Orgs.get_org!(id)

    case Orgs.ban_org(org) do
      {:ok, org} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("orgs", "org_banning_succeded"))
         |> stream_insert(:orgs, org)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, dgettext("orgs", "org_banning_failed"))}
    end
  end
end

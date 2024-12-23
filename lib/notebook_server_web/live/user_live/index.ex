defmodule NotebookServerWeb.UserLive.Index do
  use NotebookServerWeb, :live_view_app

  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.User
  alias NotebookServer.Orgs
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :users, Accounts.list_users(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, gettext("edit_user"))
    |> assign(:user, Accounts.get_user!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_user"))
    |> assign(:user, %User{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("users"))
    |> assign(:user, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.UserLive.FormComponent, {:saved, user}}, socket) do
    # TODO: check if there's a better way to do this
    org = Orgs.get_org!(user.org_id)
    user = Map.put(user, :org, org)
    {:noreply, stream_insert(socket, :users, user)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.delete_user(user)
    {:noreply, stream_delete(socket, :users, user)}
  end

  @impl true
  def handle_event("activate", %{"id" => id}, socket) do
    opts = org_filter(socket)
    user = Accounts.get_user!(id)
    {:ok, _} = Accounts.activate_user(user)
    {:noreply, stream(socket, :users, Accounts.list_users(opts))}
  end

  @impl true
  def handle_event("ban", %{"id" => id}, socket) do
    user = Accounts.get_user!(id)
    opts = org_filter(socket)
    {:ok, _} = Accounts.ban_user(user)
    {:noreply, stream(socket, :users, Accounts.list_users(opts))}
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

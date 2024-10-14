defmodule NotebookServerWeb.UserLive.Index do
  alias NotebookServer.PKIs
  use NotebookServerWeb, :live_view

  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.User
  alias NotebookServer.Orgs
  alias NotebookServer.PKIs
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
    if User.can_use_platform?(socket.assigns.current_user) do
      user = Accounts.get_user!(id)
      {:ok, _} = Accounts.delete_user(user)
      {:noreply, stream_delete(socket, :users, user)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("deactivate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      opts = org_filter(socket)
      user = Accounts.get_user!(id)
      {:ok, _} = Accounts.deactivate_user(user)
      {:noreply, stream(socket, :users, Accounts.list_users(opts))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("activate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      opts = org_filter(socket)
      user = Accounts.get_user!(id)
      {:ok, _} = Accounts.activate_user(user)
      {:noreply, stream(socket, :users, Accounts.list_users(opts))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("stop", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      user = Accounts.get_user!(id)
      opts = org_filter(socket)
      {:ok, _} = Accounts.stop_user(user)
      {:noreply, stream(socket, :users, Accounts.list_users(opts))}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("rotate_key_pair", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      # TODO: Add logic to check wether the user has a key pair or not
      user = Accounts.get_user!(id)
      public_key = PKIs.get_public_key_by_user_id(user.id)

      PKIs.rotate_key_pair(user.id, user.org_id, public_key)
      |> case do
        {:ok, _public_key} ->
          {:noreply, put_flash(socket, :info, gettext("key_pair_rotated"))}

        {:error} ->
          {:noreply, put_flash(socket, :error, gettext("error_rotating_key_pair"))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("revoke_key_pair", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      # TODO: Add logic to check wether the user has a key pair or not
      user = Accounts.get_user!(id)
      public_key = PKIs.get_public_key_by_user_id(user.id)

      PKIs.revoke_key_pair(public_key)
      |> case do
        {:ok, _public_key} ->
          {:noreply, put_flash(socket, :info, gettext("key_pair_revoked"))}

        {:error} ->
          {:noreply, put_flash(socket, :error, gettext("error_revoking_key_pair"))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("create_key_pair", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      # TODO: Add logic to check wether the user has a key pair
      user = Accounts.get_user!(id)

      PKIs.create_key_pair(user.id, user.org_id)
      |> case do
        {:ok, _public_key} ->
          {:noreply, put_flash(socket, :info, gettext("key_pair_created"))}

        {:error} ->
          {:noreply, put_flash(socket, :error, gettext("error_creating_key_pair"))}
      end
    end
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

defmodule NotebookServerWeb.KeyLive.Index do
  use NotebookServerWeb, :live_view

  alias NotebookServer.PKIs
  alias NotebookServer.Accounts.User
  alias NotebookServer.Accounts
  alias NotebookServer.Orgs
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :keys, PKIs.list_public_keys(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_key"))
    |> assign(:key, %{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("keys"))
    |> assign(:key, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.KeyLive.FormComponent, {:saved, key}}, socket) do
    # TODO: check if there's a better way to do this
    org = Orgs.get_org!(key.org_id)
    key = Map.put(key, :org, org)
    {:noreply, stream_insert(socket, :keys, key)}
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

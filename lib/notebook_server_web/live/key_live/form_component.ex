defmodule NotebookServerWeb.KeyLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.PKIs
  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.User
  alias NotebookServer.PKIs.PublicKey
  alias NotebookServerWeb.Live.Components.SelectSearch
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="key-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_component
          field={@form[:user]}
          id="user_select"
          module={SelectSearch}
          label={gettext("user")}
          options={@filtered_users}
          autocomplete="autocomplete_users"
          placeholder={gettext("email_placeholder")}
        >
          <:option :let={user}>
            <p class="text-sm p-2"><%= user.name %> <%= user.last_name %> (<%= user.email %>)</p>
          </:option>
        </.live_component>
        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:form, to_form(PKIs.change_public_key(%PublicKey{})))
     |> update_users_options()}
  end

  @impl true
  def handle_event("validate", %{"key" => key_params}, socket) do
    changeset = PKIs.change_public_key(socket.assigns.key, key_params)
    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"key" => key_params}, socket) do
    save_key(socket, socket.assigns.action, key_params)
  end

  def handle_event("autocomplete_users", %{"query" => query}, socket) do
    {:noreply, update_users_options(socket, query)}
  end

  defp save_key(socket, :new, _key_params) do
    case PKIs.create_key_pair(0, 0) do
      {:ok, key} ->
        notify_parent({:saved, key})

        {:noreply,
         socket
         |> put_flash(:info, gettext("key_create_success"))
         |> push_patch(to: socket.assigns.patch)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp update_users_options(socket, query \\ "") do
    options =
      Accounts.list_users([email: query] ++ org_filter(socket))
      |> Enum.map(fn user ->
        Map.merge(user, %{id: user.id, text: user.email})
      end)

    assign(socket, filtered_users: options)
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

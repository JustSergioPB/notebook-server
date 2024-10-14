defmodule NotebookServerWeb.UserLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.User
  alias NotebookServer.PKIs
  use Gettext, backend: NotebookServerWeb.Gettext
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="flex items-center gap-4">
          <.input
            field={@form[:name]}
            class="w-1/3"
            type="text"
            label={gettext("name")}
            placeholder={gettext("name_placeholder")}
          />
          <.input
            field={@form[:last_name]}
            class="w-2/3"
            type="text"
            label={gettext("last_name")}
            placeholder={gettext("last_name_placeholder")}
          />
        </div>
        <.input
          field={@form[:email]}
          type="text"
          label={gettext("email")}
          placeholder={gettext("email_placeholder")}
        />
        <.input
          field={@form[:role]}
          type="select"
          label={gettext("role")}
          options={[
            {gettext("org_admin"), "org_admin"},
            {gettext("user"), "user"}
          ]}
        />
        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}><%= gettext("save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      save_user(socket, socket.assigns.action, user_params)
    else
      {:noreply, socket}
    end
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, gettext("user_updated_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    org_id = socket.assigns.current_user.org_id
    user_params = Map.put(user_params, "org_id", org_id)

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        PKIs.create_key_pair(user.id, org_id)
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, gettext("user_created_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

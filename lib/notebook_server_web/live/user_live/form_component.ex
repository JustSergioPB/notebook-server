defmodule NotebookServerWeb.UserLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.User
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
        <.input field={@form[:name]} type="text" label={gettext("name")} />
        <.input field={@form[:last_name]} type="text" label={gettext("last_name")} />
        <.input field={@form[:email]} type="text" label={gettext("email")} />
        <.input
          field={@form[:role]}
          type="select"
          label={gettext("role")}
          options={["org_admin", "user"]}
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
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    user_params_with_org_id = Map.put(user_params, "org_id", socket.assigns.current_user.org_id)

    case Accounts.create_user(user_params_with_org_id) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

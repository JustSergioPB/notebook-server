defmodule NotebookServerWeb.UserLive.FormComponent do
  alias NotebookServer.Accounts
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
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
            label={dgettext("users", "name")}
            placeholder={dgettext("users", "name_placeholder")}
            phx-debounce="blur"
          />
          <.input
            field={@form[:last_name]}
            class="w-2/3"
            type="text"
            label={dgettext("users", "last_name")}
            placeholder={dgettext("users", "last_name_placeholder")}
            phx-debounce="blur"
          />
        </div>
        <.input
          field={@form[:email]}
          type="text"
          label={dgettext("users", "email")}
          placeholder={dgettext("users", "email_placeholder")}
          phx-debounce="blur"
        />
        <.input
          type="radio"
          label={dgettext("users", "role")}
          field={@form[:role]}
          options={[
            %{
              id: :issuer,
              icon: "pen-tool",
              label: dgettext("users", "issuer"),
              description: dgettext("users", "issuer_description")
            },
            %{
              id: :org_admin,
              icon: "shield",
              label: dgettext("users", "org_admin"),
              description: dgettext("users", "org_admin_description")
            }
          ]}
          phx-debounce="blur"
        />
        <:actions>
          <.button><%= gettext("save") %></.button>
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
       to_form(Accounts.change_user_create(user))
     end)}
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_create(socket.assigns.user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "password", "hello8_5AAAAAAAAA")
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("users", "update_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    org_id = socket.assigns.current_user.org_id
    user_params = Map.put(user_params, "org_id", org_id)

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("users", "creation_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

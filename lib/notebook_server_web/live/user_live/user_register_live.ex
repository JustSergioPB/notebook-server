defmodule NotebookServerWeb.UserRegisterLive do
  use NotebookServerWeb, :live_view_auth
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Accounts
  alias NotebookServer.Accounts.UserRegister

  def render(assigns) do
    ~H"""
    <div class="w-1/2 space-y-12">
      <.header>
        <%= gettext("register_title") %>
        <:subtitle>
          <%= gettext("register_subtitle") %>
        </:subtitle>
      </.header>
      <.simple_form for={@form} phx-change="validate" phx-submit="register">
        <div class="flex items-center gap-4">
          <.input
            class="w-1/3"
            field={@form[:name]}
            type="text"
            label={gettext("name")}
            placeholder={gettext("name_placeholder")}
            phx-debounce="blur"
            required
          />
          <.input
            class="w-2/3"
            field={@form[:last_name]}
            type="text"
            label={gettext("last_name")}
            placeholder={gettext("last_name_placeholder")}
            phx-debounce="blur"
            required
          />
        </div>
        <.input
          field={@form[:org_name]}
          type="text"
          label={gettext("org_name")}
          placeholder={gettext("org_name_placeholder")}
          phx-debounce="blur"
          required
        />
        <.input
          field={@form[:email]}
          type="email"
          label={gettext("email")}
          placeholder={gettext("email_placeholder")}
          phx-debounce="blur"
          required
        />
        <.input
          field={@form[:password]}
          type="password"
          label={gettext("password")}
          placeholder={gettext("password_placeholder")}
          phx-debounce="blur"
          required
        />
        <:actions>
          <.button class="w-full" icon="rocket">
            <%= gettext("register") %>
          </.button>
        </:actions>
      </.simple_form>
      <div class="text-sm gap-2 text-center">
        <%= gettext("already_have_account") %>
        <.link class="font-bold hover:underline" patch={~p"/login"}>
          <%= gettext("login") %>
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_register(%UserRegister{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  def handle_event("validate", %{"user_register" => user_params}, socket) do
    changeset = Accounts.change_user_register(%UserRegister{}, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("register", %{"user_register" => user_params}, socket) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("user_register_success"))
         |> redirect(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset))
         |> put_flash(:error, gettext("user_register_error"))}
    end
  end
end

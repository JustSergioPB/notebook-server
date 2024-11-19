defmodule NotebookServerWeb.UserLoginLive do
  use NotebookServerWeb, :live_view_auth
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-12 lg:w-1/2 lg:p-0">
      <.header>
        <%= gettext("login_title") %>
        <:subtitle>
          <%= gettext("login_subtitle") %>
        </:subtitle>
      </.header>
      <.simple_form for={@form} id="login_form" action={~p"/login"} phx-update="ignore">
        <.input
          field={@form[:email]}
          type="email"
          label={gettext("email")}
          placeholder={gettext("email_placeholder")}
          required
        />
        <.input
          field={@form[:password]}
          type="password"
          label={gettext("password")}
          placeholder={gettext("password_placeholder")}
          required
        />
        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label={gettext("remember_me")} />
          <.link href={~p"/reset-password"} class="text-sm font-semibold hover:underline">
            <%= gettext("forgot_password") %>
          </.link>
        </:actions>
        <:actions>
          <.button class="w-full" icon="log-in">
            <%= gettext("login") %>
          </.button>
        </:actions>
      </.simple_form>
      <div class="space-y-4">
        <div class="text-sm gap-2 text-center">
          <%= gettext("dont_have_account") %>
          <.link class="font-bold hover:underline" patch={~p"/register"}>
            <%= gettext("register") %>
          </.link>
        </div>
        <div class="text-sm gap-2 text-center">
          <%= gettext("dont_have_confirmation") %>
          <.link class="font-bold hover:underline" patch={~p"/confirm"}>
            <%= gettext("confirm") %>
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

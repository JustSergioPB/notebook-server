defmodule NotebookServerWeb.UserLoginLive do
  use NotebookServerWeb, :live_view_auth

  def render(assigns) do
    ~H"""
    <div class="w-1/2">
      <.header class="mb-12">
        Welcome back!
        <:subtitle>
          Enter your credentials to continue.
        </:subtitle>
      </.header>
      <.simple_form for={@form} id="login_form" action={~p"/login"} phx-update="ignore">
        <.input
          field={@form[:email]}
          type="email"
          label="Email"
          placeholder="johndoe@example.com"
          required
        />
        <.input
          field={@form[:password]}
          type="password"
          label="Password"
          placeholder="mycoolpassword"
          required
        />
        <:actions>
          <.input field={@form[:remember_me]} type="checkbox" label="Remember me" />
          <.link href={~p"/reset-password"} class="text-sm font-semibold hover:underline">
            Forgot your password?
          </.link>
        </:actions>
        <:actions>
          <.button class="w-full" icon="log-in">
            Log in
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end

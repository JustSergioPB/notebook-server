defmodule NotebookServerWeb.UserForgotPasswordLive do
  use NotebookServerWeb, :live_view_auth

  alias NotebookServer.Accounts

  def render(assigns) do
    ~H"""
    <div class="w-1/2">
      <.header class="mb-12">
        Forgot your password?
        <:subtitle>We'll send a link to reset your password to your inbox</:subtitle>
      </.header>
      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input
          field={@form[:email]}
          type="email"
          placeholder="johndoe@example.com"
          label="Email"
          required
        />
        <:actions>
          <.button icon="send" class="w-full">
            Send link
          </.button>
        </:actions>
      </.simple_form>
      <div class="flex justify-center">
        <.link class="text-center text-sm mt-4 font-semibold hover:underline" href={~p"/login"}>
          Log in
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_email", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/reset-password/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(:info, "If your email is in our system, you will receive instructions to reset your password shortly.")
     |> redirect(to: ~p"/")}
  end
end

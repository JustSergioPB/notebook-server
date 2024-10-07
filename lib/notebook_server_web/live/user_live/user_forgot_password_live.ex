defmodule NotebookServerWeb.UserForgotPasswordLive do
  use NotebookServerWeb, :live_view_auth

  alias NotebookServer.Accounts
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <div class="w-1/2">
      <.header class="mb-12">
        <%= gettext("forgot_password_title") %>
        <:subtitle><%= gettext("forgot_password_subtitle") %></:subtitle>
      </.header>
      <.simple_form for={@form} id="reset_password_form" phx-submit="send_email">
        <.input
          field={@form[:email]}
          type="email"
          placeholder={gettext("email_placeholder")}
          label={gettext("email")}
          required
        />
        <:actions>
          <.button icon="send" class="w-full">
            <%= gettext("send_link") %>
          </.button>
        </:actions>
      </.simple_form>
      <div class="flex justify-center">
        <.link class="text-center text-sm mt-4 font-semibold hover:underline" href={~p"/login"}>
          <%= gettext("login") %>
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
     |> put_flash(:info, gettext("reset_email_sent"))
     |> redirect(to: ~p"/")}
  end
end

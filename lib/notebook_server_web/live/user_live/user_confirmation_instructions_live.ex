defmodule NotebookServerWeb.UserConfirmationInstructionsLive do
  use NotebookServerWeb, :live_view_auth
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Accounts

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-12 lg:w-1/2 lg:p-0">
      <.header>
        <%= gettext("confirmation_instructions_title") %>
        <:subtitle>
          <%= gettext("confirmation_instructions_subtitle") %>
        </:subtitle>
      </.header>

      <.simple_form for={@form} id="resend_confirmation_form" phx-submit="send_instructions">
        <.input
          field={@form[:email]}
          type="email"
          label={gettext("email")}
          placeholder={gettext("email_placeholder")}
          required
        />
        <:actions>
          <.button icon="send" class="w-full">
            <%= gettext("resend") %>
          </.button>
        </:actions>
      </.simple_form>

      <div class="flex items-center justify-center gap-4">
        <.link class="w-1/2" href={~p"/register"}>
          <.button class="w-full" variant="ghost">
            <%= gettext("register") %>
          </.button>
        </.link>
        <.link class="w-1/2" href={~p"/login"}>
          <.button class="w-full" variant="ghost">
            <%= gettext("login") %>
          </.button>
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(%{}, as: "user"))}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/confirm/#{&1}")
      )
    end

    info =
      gettext("confirmation_instructions_info")

    {:noreply,
     socket
     |> put_flash(:info, info)
     |> redirect(to: ~p"/")}
  end
end

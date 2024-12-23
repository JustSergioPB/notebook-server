defmodule NotebookServerWeb.UserForgotPasswordLive do
  use NotebookServerWeb, :live_view_auth

  alias NotebookServer.Accounts
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <div class="p-6 lg:w-1/2 lg:p-0">
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
    user = Accounts.get_user_by_email(email)

    if !is_nil(user) do
      Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/reset-password/#{&1}")
      )
      |> case do
        {:ok, _} ->
          {:noreply,
           socket
           |> put_flash(:info, gettext("reset_email_sent"))
           |> redirect(to: ~p"/")}

        {:error, error} ->
          {:noreply, socket |> put_flash(:error, error)}
      end
    else
      {:noreply, socket}
    end
  end
end

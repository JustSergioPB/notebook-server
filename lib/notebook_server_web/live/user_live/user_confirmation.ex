defmodule NotebookServerWeb.UserConfirmationLive do
  use NotebookServerWeb, :live_view_auth
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="w-1/2 space-y-12">
      <.header>
        <%= gettext("confirm_account_title") %>
        <:subtitle>
          <%= gettext("confirm_account_subtitle") %>
        </:subtitle>
      </.header>
      <.simple_form for={@form} id="confirmation_form" phx-submit="confirm_account">
          <input type="hidden" name={@form[:token].name} value={@form[:token].value} />
          <:actions>
            <.button icon="badge-check" class="w-full"><%= gettext("confirm") %></.button>
          </:actions>
        </.simple_form>
      <div class="flex gap-4">
        <.button_link class="w-1/2" variant="ghost" href={~p"/register"}><%= gettext("register") %></.button_link>
        <.button_link class="w-1/2" variant="ghost" href={~p"/login"}><%= gettext("login") %></.button_link>
      </div>
    </div>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    form = to_form(%{"token" => token}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after confirmation to avoid a
  # leaked token giving the user access to the account.
  def handle_event("confirm_account", %{"user" => %{"token" => token}}, socket) do
    case Accounts.confirm_user(token) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("user_confirmed_successfully"))
         |> redirect(to: ~p"/dashboard")}

      :error ->
        # If there is a current user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the user themselves, so we redirect without
        # a warning message.
        case socket.assigns do
          %{current_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            {:noreply, redirect(socket, to: ~p"/dashboard")}

          %{} ->
            {:noreply,
             socket
             |> put_flash(:error, gettext("user_confirmation_link_invalid_or_expired"))
             |> redirect(to: ~p"/dashboard")}
        end
    end
  end
end

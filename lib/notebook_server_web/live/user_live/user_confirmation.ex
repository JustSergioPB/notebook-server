defmodule NotebookServerWeb.UserConfirmationLive do
  use NotebookServerWeb, :live_view_auth
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServer.Accounts

  def render(%{live_action: :edit} = assigns) do
    ~H"""
    <div class="p-6 space-y-12 lg:w-1/2 lg:p-0">
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

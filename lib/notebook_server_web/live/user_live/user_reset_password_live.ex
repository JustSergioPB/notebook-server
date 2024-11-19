defmodule NotebookServerWeb.UserResetPasswordLive do
  use NotebookServerWeb, :live_view_auth

  alias NotebookServer.Accounts
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-12 lg:w-1/2 lg:p-0">
      <.header class="mb-12">
        <%= gettext("reset_password_title") %>
        <:subtitle>
          <%= gettext("reset_password_subtitle") %>
        </:subtitle>
      </.header>
      <.simple_form
        for={@form}
        id="reset_password_form"
        phx-submit="reset_password"
        phx-change="validate"
      >
        <.input
          field={@form[:password]}
          type="password"
          label={gettext("new_password")}
          placeholder={gettext("new_password_placeholder")}
          phx-debounce="blur"
          required
        />
        <.input
          field={@form[:password_confirmation]}
          type="password"
          label={gettext("confirm_new_password")}
          placeholder={gettext("confirm_new_password_placeholder")}
          phx-debounce="blur"
          required
        />
        <.error :if={@form.errors != []}>
          <%= gettext("oops_something_went_wrong") %>
        </.error>
        <:actions>
          <.button icon="rotate-ccw" class="w-full">
            <%= gettext("reset") %>
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

  def mount(params, _session, socket) do
    socket = assign_user_and_token(socket, params)

    form_source =
      case socket.assigns do
        %{user: user} ->
          Accounts.change_user_password(user)

        _ ->
          %{}
      end

    {:ok, assign_form(socket, form_source), temporary_assigns: [form: nil]}
  end

  # Do not log in the user after reset password to avoid a
  # leaked token giving the user access to the account.
  def handle_event("reset_password", %{"user" => user_params}, socket) do
    case Accounts.reset_user_password(socket.assigns.user, user_params) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("password_reset_successfully"))
         |> redirect(to: ~p"/login")}

      {:error, changeset} ->
        {:noreply, assign_form(socket, Map.put(changeset, :action, :insert))}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_password(socket.assigns.user, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_user_and_token(socket, %{"token" => token}) do
    if user = Accounts.get_user_by_reset_password_token(token) do
      assign(socket, user: user, token: token)
    else
      socket
      |> put_flash(:error, gettext("reset_password_link_is_invalid_or_expired"))
      |> redirect(to: ~p"/")
    end
  end

  defp assign_form(socket, %{} = source) do
    assign(socket, :form, to_form(source, as: "user"))
  end
end

defmodule NotebookServerWeb.UserSettingsLive do
  use NotebookServerWeb, :live_view

  alias NotebookServer.Accounts
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <.page_header icon="settings">
      <%= gettext("settings_title") %>
    </.page_header>

    <.tabs active_tab={@active_tab} tab_content_class="p-6">
      <:tab label={gettext("account")} id="account" patch={~p"/settings?tab=account"}>
        <.simple_form class="w-1/2" for={@form} phx-change="validate" phx-submit="save">
          <div class="flex space-x-4">
            <.input
              class="basis-1/3"
              field={@form[:name]}
              type="text"
              label={gettext("name")}
              placeholder={gettext("name_placeholder")}
              phx-debounce="blur"
            />
            <.input
              class="basis-2/3"
              field={@form[:last_name]}
              type="text"
              label={gettext("last_name")}
              placeholder={gettext("last_name_placeholder")}
              phx-debounce="blur"
            />
          </div>
          <.input
            field={@form[:email]}
            type="email"
            label={gettext("email")}
            placeholder={gettext("email_placeholder")}
            disabled
          />
          <.input
            field={@form[:role]}
            type="select"
            label={gettext("role")}
            options={[
              {gettext("admin"), "admin"},
              {gettext("org_admin"), "org_admin"},
              {gettext("issuer"), "issuer"}
            ]}
            disabled
          />
          <.input
            field={@form[:language]}
            type="select"
            label={gettext("language")}
            options={[
              "🇺🇸 English": "en",
              "🇪🇸 Español": "es"
            ]}
          />
          <:actions>
            <.button><%= gettext("save") %></.button>
          </:actions>
        </.simple_form>
      </:tab>
    </.tabs>
    """
  end

  def mount(%{"token" => token}, _session, socket) do
    socket =
      case Accounts.update_user_email(socket.assigns.current_user, token) do
        :ok ->
          put_flash(socket, :info, gettext("email_changed_successfully"))

        :error ->
          put_flash(socket, :error, gettext("email_change_link_is_invalid_or_expired"))
      end

    {:ok, push_navigate(socket, to: ~p"/settings")}
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    form = Accounts.change_user_settings(user)

    {:ok, socket |> assign(:form, to_form(form))}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> assign(:active_tab, params["tab"] || "account")}
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_settings(socket.assigns.current_user, user_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    case Accounts.update_user_settings(socket.assigns.current_user, user_params) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> redirect(to: ~p"/settings")
         |> put_flash(:info, gettext("settings_updated_successfully"))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("settings_update_error"))
         |> assign(form: to_form(changeset))}
    end
  end

  def handle_event("validate_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params

    password_form =
      socket.assigns.current_user
      |> Accounts.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event("update_password", params, socket) do
    %{"current_password" => password, "user" => user_params} = params
    user = socket.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Accounts.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end

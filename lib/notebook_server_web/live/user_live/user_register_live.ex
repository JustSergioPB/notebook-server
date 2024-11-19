defmodule NotebookServerWeb.UserRegisterLive do
  alias NotebookServer.Orgs
  alias NotebookServer.Orgs.Org
  alias NotebookServer.Accounts.User
  use NotebookServerWeb, :live_view_auth
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-12 lg:w-1/2 lg:p-0">
      <.header>
        <%= dgettext("orgs", "register_title") %>
        <:subtitle>
          <%= dgettext("orgs", "register_subtitle") %>
        </:subtitle>
      </.header>
      <.simple_form
        for={@form}
        id="registration_form"
        phx-change="validate"
        phx-submit="register"
        phx-trigger-action={@trigger_submit}
        action={~p"/login?_action=registered"}
        method="post"
      >
        <section class="divide-y divide-solid divide-slate-300">
          <section class="mb-4">
            <h3 class="font-semibold mb-2"><%= dgettext("orgs", "org") %></h3>
            <div class="space-y-4">
              <.input
                field={@form[:name]}
                type="text"
                label={dgettext("orgs", "name")}
                placeholder={dgettext("orgs", "name_placeholder")}
                phx-debounce="blur"
                required
              />
              <.input
                field={@form[:email]}
                type="email"
                label={dgettext("orgs", "email")}
                placeholder={dgettext("orgs", "email_placeholder")}
                phx-debounce="blur"
                required
              />
            </div>
          </section>
          <section>
            <h3 class="font-semibold mt-4 mb-2"><%= dgettext("users", "user") %></h3>
            <div class="space-y-4">
              <.inputs_for :let={user_form} field={@form[:users]}>
                <div class="flex items-center gap-4">
                  <.input
                    class="w-1/3"
                    field={user_form[:name]}
                    type="text"
                    label={dgettext("users", "name")}
                    placeholder={dgettext("users", "name_placeholder")}
                    phx-debounce="blur"
                    required
                  />
                  <.input
                    class="w-2/3"
                    field={user_form[:last_name]}
                    type="text"
                    label={dgettext("users", "last_name")}
                    placeholder={dgettext("users", "last_name_placeholder")}
                    phx-debounce="blur"
                    required
                  />
                </div>
                <.input
                  field={user_form[:email]}
                  type="email"
                  label={dgettext("users", "email")}
                  placeholder={dgettext("users", "email_placeholder")}
                  phx-debounce="blur"
                  required
                />
                <.input
                  field={user_form[:password]}
                  type="password"
                  label={dgettext("users", "password")}
                  placeholder={dgettext("users", "password_placeholder")}
                  phx-debounce="blur"
                  required
                />
              </.inputs_for>
            </div>
          </section>
        </section>
        <:actions>
          <.button class="w-full" icon="rocket">
            <%= dgettext("orgs", "register") %>
          </.button>
        </:actions>
      </.simple_form>
      <div class="text-sm gap-2 text-center">
        <%= dgettext("users", "already_have_account") %>
        <.link class="font-bold hover:underline" patch={~p"/login"}>
          <%= dgettext("users", "login") %>
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(trigger_submit: false)
     |> assign(form: to_form(Orgs.change_org(%Org{users: [%User{}]}, %{}, user: true)))}
  end

  def handle_event("validate", %{"org" => org_params}, socket) do
    {:noreply,
     socket
     |> assign(
       form:
         to_form(Orgs.change_org(%Org{users: [%User{}]}, org_params, user: true),
           action: :validate
         )
     )}
  end

  def handle_event("register", %{"org" => org_params}, socket) do
    case Orgs.register_org(org_params, &url(~p"/confirm/#{&1}")) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("orgs", "org_registration_succeded"))
         |> assign(trigger_submit: true)}

      {:error, changeset, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("orgs", "org_registration_failed"))
         |> assign(form: to_form(changeset))}

      # TODO: add a screen to allow the user to resend the confirmation email
      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("orgs", "registration_mail_delivery_failed"))}
    end
  end
end

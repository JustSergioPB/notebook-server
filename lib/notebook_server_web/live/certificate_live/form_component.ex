defmodule NotebookServerWeb.CertificateLive.FormComponent do
  alias NotebookServer.Accounts
  alias NotebookServer.Orgs
  alias NotebookServer.Certificates
  alias NotebookServerWeb.Components.SelectSearch
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <.header>
        <%= @title %>
      </.header>
      <.simple_form for={@form} id="certificate-form" phx-target={@myself} phx-submit="save">
        <.live_component
          field={@form[:org_id]}
          id={@form[:org_id].id}
          module={SelectSearch}
          label={dgettext("orgs", "search")}
          options={@org_options}
          placeholder={dgettext("orgs", "name_placeholder") <> "..."}
          autocomplete="autocomplete_orgs"
          target="#certificate-form"
        >
          <:option :let={org}>
            <p class="font-bold"><%= org.name %></p>
          </:option>
        </.live_component>
        <.live_component
          :if={@tab == "user"}
          field={@form[:user_id]}
          id={@form[:user_id].id}
          module={SelectSearch}
          label={dgettext("users", "search")}
          options={@user_options}
          placeholder={dgettext("users", "email_placeholder") <> "..."}
          autocomplete="autocomplete_users"
          target="#certificate-form"
        >
          <:option :let={user}>
            <.user_version_option user={user} />
          </:option>
        </.live_component>
        <.inputs_for :let={certificate_form} field={@form[:certificate]}>
          <.input
            field={certificate_form[:level]}
            type="select"
            label={gettext("level")}
            options={[
              {dgettext("certificates", "entity"), "entity"},
              {dgettext("certificates", "intermediate"), "intermediate"},
              {dgettext("certificates", "root"), "root"}
            ]}
            phx-debounce="blur"
            disabled={@tab == "user"}
          />
        </.inputs_for>
        <:actions>
          <.button>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{certificate: certificate, tab: tab} = assigns, socket) do
    atom = tab |> String.to_atom()
    changeset = Certificates.change_certificate(atom, certificate)

    {:ok,
     socket
     |> assign(assigns)
     |> update_user_options()
     |> update_org_options()
     |> assign_new(:form, fn -> to_form(changeset) end)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    atom = socket.assigns.tab |> String.to_atom()

    changeset =
      Certificates.change_certificate(
        atom,
        socket.assigns.certificate,
        params["#{socket.assigns.tab}_certificate"]
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", params, socket) do
    atom = socket.assigns.tab |> String.to_atom()

    case Certificates.create_certificate(atom, params["#{socket.assigns.tab}_certificate"]) do
      {:ok, certificate, message} ->
        notify_parent({:saved, atom, certificate})
        {:noreply, socket |> put_flash(:info, message) |> push_patch(to: socket.assigns.patch)}

      {:error, changeset, message} ->
        {:noreply, socket |> put_flash(:error, message) |> assign(:form, to_form(changeset))}

      {:error, message} ->
        {:noreply, socket |> put_flash(:error, message)}
    end
  end

  def handle_event("autocomplete_orgs", %{"query" => query}, socket) do
    {:noreply, update_org_options(socket, query)}
  end

  def handle_event("autocomplete_users", %{"query" => query}, socket) do
    # TODO remove company filtering for user search
    {:noreply, update_user_options(socket, query)}
  end

  defp update_org_options(socket, query \\ "") do
    options =
      Orgs.list_orgs(name: query)
      |> Enum.map(fn org ->
        org |> Map.put(:text, org.name)
      end)

    assign(socket, org_options: options)
  end

  defp update_user_options(socket, query \\ "") do
    options =
      Accounts.list_users(email: query)
      |> Enum.map(fn user ->
        user
        |> Map.put(:text, user.email)
      end)

    assign(socket, user_options: options)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

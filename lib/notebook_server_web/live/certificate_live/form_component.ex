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
    <div <div class="h-full flex flex-col">
      <.header class="p-6">
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="certificate-form"
        phx-target={@myself}
        phx-submit="save"
        variant="app"
      >
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
     |> assign_new(:form, fn -> to_form(changeset, as: "certificate") end)}
  end

  @impl true
  def handle_event("validate", %{"certificate" => certificate_params}, socket) do
    atom = socket.assigns.tab |> String.to_atom()

    changeset =
      Certificates.change_certificate(
        atom,
        socket.assigns.certificate,
        certificate_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "certificate"))}
  end

  def handle_event("save", %{"certificate" => certificate_params}, socket) do
    atom = socket.assigns.tab |> String.to_atom()
    certificate_params = complete_credential(atom, certificate_params, socket)

    case Certificates.create_certificate(atom, certificate_params) do
      {:ok, %{create_certificate: certificate}} ->
        notify_parent({:saved, atom, certificate})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("certificates", "creation_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, :create_certificate, _, _} ->
        {:noreply, put_flash(socket, :error, dgettext("certificates", "creation_failed"))}

      {:error, :store_private_key, _, _} ->
        {:noreply,
         put_flash(socket, :error, dgettext("certificates", "private_key_storation_failed"))}
    end
  end

  def handle_event("autocomplete_orgs", %{"query" => query}, socket) do
    {:noreply, update_org_options(socket, query)}
  end

  def handle_event("autocomplete_users", %{"query" => query}, socket) do
    # TODO remove company filtering for user search
    {:noreply, update_user_options(socket, query)}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp update_org_options(socket, query \\ "") do
    options =
      Orgs.list_orgs(name: query)
      |> Enum.map(fn org ->
        org |> Map.merge(%{text: org.name, id: Integer.to_string(org.id)})
      end)

    assign(socket, org_options: options)
  end

  defp update_user_options(socket, query \\ "") do
    options =
      Accounts.list_users(email: query)
      |> Enum.map(fn user ->
        user
        |> Map.merge(%{text: user.email, id: Integer.to_string(user.id)})
      end)

    assign(socket, user_options: options)
  end

  defp complete_credential(:org, certificate_params, socket) do
    org =
      socket.assigns.org_options
      |> Enum.find(fn option -> option.id == Map.get(certificate_params, "org_id") end)

    level = get_in(certificate_params, ["certificate", "level"]) |> String.to_atom()

    Certificates.complete_certificate(:org, org, level)
  end

  defp complete_credential(:user, certificate_params, socket) do
    org =
      socket.assigns.org_options
      |> Enum.find(fn option -> option.id == Map.get(certificate_params, "org_id") end)

    user =
      socket.assigns.user_options
      |> Enum.find(fn option -> option.id == Map.get(certificate_params, "user_id") end)

    Certificates.complete_certificate(:user, org, user)
  end
end

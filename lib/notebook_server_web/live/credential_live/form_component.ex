defmodule NotebookServerWeb.CredentialLive.FormComponent do
  alias NotebookServer.Schemas.SchemaVersion
  alias NotebookServer.Credentials.UserCredential
  alias NotebookServer.Schemas
  alias NotebookServer.Credentials
  alias NotebookServer.Accounts.User
  alias NotebookServer.Credentials
  alias NotebookServerWeb.Components.SelectSearch
  alias NotebookServerWeb.JsonSchemaComponents
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.simple_form
        for={@select_form}
        class={if @step == 0, do: "flex", else: "hidden"}
        phx-target={@myself}
        id="select-form"
        phx-submit="next"
      >
        <.live_component
          field={@select_form[:schema_id]}
          id={@select_form[:schema_id].id}
          module={SelectSearch}
          label={gettext("search_schema")}
          options={@schema_version_options}
          placeholder={gettext("title_placeholder") <> "..."}
          autocomplete="autocomplete_schemas"
          target="#select-form"
        >
          <:option :let={schema}>
            <.schema_version_option schema={schema} />
          </:option>
        </.live_component>
        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("next") %>
          </.button>
        </:actions>
      </.simple_form>
      <.simple_form
        id="credential-form"
        class={if @step == 1, do: "flex", else: "hidden"}
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="next"
      >
        <.inputs_for :let={credential_form} :if={@step == 1} field={@form[:credential]}>
          <.inputs_for :let={credential_content_form} field={credential_form[:content]}>
            <.inputs_for
              :let={credential_subject_form}
              field={credential_content_form[:credential_subject]}
            >
              <JsonSchemaComponents.json_schema_node
                field={credential_subject_form[:content]}
                schema={@schema_version.credential_subject_content}
              />
            </.inputs_for>
          </.inputs_for>
        </.inputs_for>
        <:actions>
          <.button
            variant="outline"
            disabled={!User.can_use_platform?(@current_user)}
            type="button"
            phx-target={@myself}
            phx-click="back"
          >
            <%= gettext("back") %>
          </.button>
          <.button disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("next") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:step, fn -> 0 end)
     |> update_schema_options()
     |> assign_new(:select_form, fn ->
       to_form(%{"schema_id" => ""})
     end)
     |> assign_new(:schema_version, fn -> nil end)
     |> assign_new(:form, fn ->
       to_form(Credentials.change_credential(:user, %UserCredential{}))
     end)}
  end

  @impl true
  def handle_event("autocomplete_schemas", %{"query" => query}, socket) do
    {:noreply, update_schema_options(socket, query)}
  end

  def handle_event("validate", %{"user_credential" => credential_params}, socket) do
    credential_params = socket |> gen_complete_credential(credential_params)
    changeset = Credentials.change_credential(:user, socket.assigns.credential, credential_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("back", _, socket) do
    {:noreply, socket |> assign(:step, socket.assigns.step - 1)}
  end

  def handle_event("next", %{"schema_id" => schema_id}, socket) when schema_id != "" do
    schema_version =
      socket.assigns.schema_version_options
      |> Enum.find(fn schema_version -> schema_version.id == String.to_integer(schema_id) end)

    socket =
      socket
      |> assign(:schema_version, schema_version)
      |> assign(:step, socket.assigns.step + 1)

    {:noreply, socket}
  end

  def handle_event("next", %{"schema_id" => _}, socket) do
    socket =
      socket
      |> assign(
        :form,
        to_form(%{"schema_id" => ""},
          error: [schema_id: gettext("field_required")],
          action: :validate
        )
      )

    {:noreply, socket}
  end

  def handle_event("next", %{"user_credential" => credential_params}, socket) do
    credential_params = socket |> gen_complete_credential(credential_params)

    case Credentials.create_credential(:user, credential_params) do
      {:ok, credential, message} ->
        notify_parent({:saved, credential})

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> push_patch(to: socket.assigns.patch)}

      {:error, message} ->
        {:noreply, socket |> put_flash(:error, message)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end

  defp update_schema_options(socket, query \\ "") do
    options =
      Schemas.list_schema_versions([title: query, status: :published] ++ org_filter(socket))
      |> Enum.map(fn schema_version ->
        schema_version
        |> SchemaVersion.get_credential_subject_content()
        |> Map.put(:text, schema_version.schema.title)
      end)

    assign(socket, schema_version_options: options)
  end

  defp gen_complete_credential(socket, credential_params) do
    user = socket.assigns.current_user
    org = socket.assigns.current_user.org
    schema_version = socket.assigns.schema_version

    credential_params |> UserCredential.gen_full(org, user, schema_version)
  end
end

defmodule NotebookServerWeb.CredentialLive.FormComponent do
  alias NotebookServer.Credentials.Credential
  use NotebookServerWeb, :live_component

  alias NotebookServer.Schemas
  alias NotebookServer.Credentials
  alias NotebookServer.Accounts.User
  alias NotebookServer.Credentials
  alias NotebookServerWeb.Components.SelectSearch
  alias NotebookServerWeb.JsonSchemaComponents
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
          options={@schema_options}
          placeholder={gettext("title_placeholder") <> "..."}
          autocomplete="autocomplete_schemas"
          target="#select-form"
        >
          <:option :let={schema}>
            <p class="font-bold"><%= schema.text %></p>
            <p><%= schema.description %></p>
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
        phx-submit="save"
      >
        <JsonSchemaComponents.json_schema_node
          :if={is_map(@schema)}
          field={@form[:raw_content]}
          schema={@schema.credential_subject}
        />
        <:actions>
          <.button
            variant="outline"
            disabled={!User.can_use_platform?(@current_user)}
            type="button"
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
     |> update_schema_options()
     |> assign(:step, 0)
     |> assign(:schema, nil)
     |> assign_new(:select_form, fn ->
       to_form(%{"schema_id" => ""})
     end)
     |> assign_new(:form, fn ->
       to_form(%{})
     end)}
  end

  @impl true
  def handle_event("autocomplete_schemas", %{"query" => query}, socket) do
    {:noreply, update_schema_options(socket, query)}
  end

  def handle_event("validate", %{"credential" => credential_params}, socket) do
    credential_params =
      credential_params
      |> add_extra_params(socket)

    changeset =
      Credentials.change_credential(
        %Credential{},
        socket.assigns.schema.credential_subject,
        credential_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("back", _, socket) do
    {:noreply, socket |> assign(:step, socket.assigns.step - 1)}
  end

  def handle_event("next", params, socket) do
    {:noreply, socket |> handle_step(params)}
  end

  def handle_event("save", %{"credential" => credential_params}, socket) do
    credential_params =
      credential_params
      |> add_extra_params(socket)

    case Credentials.create_credential(credential_params) do
      {:ok, credential} ->
        notify_parent({:saved, credential})

        {:noreply,
         socket
         |> put_flash(:info, gettext("credential_created_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
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
      Schemas.list_schemas([title: query] ++ org_filter(socket))
      |> Enum.map(fn schema ->
        published_version =
          schema.schema_versions |> Enum.find(fn version -> version.status == :published end)

        credential_subject = if published_version, do: published_version.credential_subject

        schema
        |> Schemas.map_to_row()
        |> Map.merge(%{text: schema.title, credential_subject: credential_subject})
      end)
      |> Enum.filter(fn schema ->
        !is_nil(schema.credential_subject)
      end)

    assign(socket, schema_options: options)
  end

  defp handle_step(socket, %{"schema_id" => schema_id}) do
    socket =
      if String.length(schema_id) > 0 do
        next_step = socket.assigns.step + 1

        schema =
          socket.assigns.schema_options
          |> Enum.find(fn schema -> schema.id == String.to_integer(schema_id) end)

        changeset = Credentials.change_credential(%Credential{}, schema.credential_subject)

        socket
        |> assign(:step, next_step)
        |> assign(:schema, schema)
        |> assign(:form, to_form(changeset))
      else
        socket
        |> assign(
          :form,
          to_form(%{"schema_id" => ""},
            error: [schema_id: gettext("field_required")],
            action: :validate
          )
        )
      end

    socket
  end

  defp handle_step(socket, _), do: socket

  defp add_extra_params(credential_params, socket) do
    IO.inspect(socket.assigns.current_user.org_id)
    IO.inspect(socket.assigns.current_user.id)
    IO.inspect(socket.assigns.schema.id)

    credential_params
    |> Map.merge(%{
      "org_id" => socket.assigns.current_user.org_id,
      "issuer_id" => socket.assigns.current_user.id,
      "schema_id" => socket.assigns.schema.id,
      "credential_id" => "coming-soon",
      "schema_version_id" => "TODO"
    })
  end
end

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
          options={@schema_version_options}
          placeholder={gettext("title_placeholder") <> "..."}
          autocomplete="autocomplete_schemas"
          target="#select-form"
        >
          <:option :let={schema}>
            <div class="flex items-center gap-1">
              <div class="bg-white shadow-sm border border-slate-200 py-1 px-2 rounded-xl text-xs font-semibold">
                V<%= schema.version_number %>
              </div>
              <p class="font-bold"><%= schema.text %></p>
            </div>
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
          :if={is_map(@schema_version)}
          field={@form[:raw_content]}
          schema={@schema_version.raw_content}
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
     |> assign(:schema_version, nil)
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
        socket.assigns.schema.raw_content,
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
      Schemas.list_schema_versions([title: query, status: :published] ++ org_filter(socket))
      |> Enum.map(fn schema_version ->
        schema_version |> Map.merge(%{text: schema_version.title})
      end)

    assign(socket, schema_version_options: options)
  end

  defp handle_step(socket, %{"schema_id" => schema_id}) when schema_id != "" do
    schema_version =
      socket.assigns.schema_version_options
      |> Enum.find(fn schema_version -> schema_version.id == String.to_integer(schema_id) end)

    raw_content = schema_version |> Map.get(:raw_content)
    raw_content_decoded = Jason.decode!(raw_content)
    schema_version = schema_version |> Map.put(:raw_content, raw_content_decoded)

    changeset = Credentials.change_credential(%Credential{}, schema_version)

    socket
    |> assign(:step, socket.assigns.step + 1)
    |> assign(:schema_version, schema_version)
    |> assign(:form, to_form(changeset))
  end

  defp handle_step(socket, %{"schema_id" => _}) do
    socket
    |> assign(
      :form,
      to_form(%{"schema_id" => ""},
        error: [schema_id: gettext("field_required")],
        action: :validate
      )
    )
  end

  defp handle_step(socket, _), do: socket

  defp add_extra_params(credential_params, socket) do
    credential_params
    |> Map.merge(%{
      "org_id" => socket.assigns.current_user.org_id,
      "issuer_id" => socket.assigns.current_user.id,
      "schema_id" => socket.assigns.schema_version.schema_id,
      "schema_version_id" => socket.assigns.schema_version.id,
      "credential_id" => "TODO"
    })
  end
end

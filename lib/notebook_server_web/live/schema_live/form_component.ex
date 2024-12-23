defmodule NotebookServerWeb.SchemaLive.FormComponent do
  alias NotebookServer.Schemas
  alias NotebookServer.Schemas.Schema
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <.header class="p-6">
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="schema-form"
        variant="app"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.info_banner
          :if={!@latest_is_in_draft?}
          content={dgettext("schemas", "latest_is_not_in_draft")}
          variant="warn"
        />
        <.input
          type="text"
          field={@form[:title]}
          label={dgettext("schemas", "title")}
          placeholder={dgettext("schemas", "title_placeholder")}
          hint={gettext("max_chars %{max}", max: 50)}
          phx-debounce="blur"
          required
        />
        <.input
          type="textarea"
          rows="2"
          field={@form[:description]}
          label={dgettext("schemas", "description")}
          placeholder={dgettext("schemas", "description_placeholder")}
          hint={gettext("max_chars %{max}", max: 255)}
          phx-debounce="blur"
        />
        <.input
          type="textarea"
          field={@form[:content]}
          value={Jason.encode!(@form[:content].value || %{}, pretty: true)}
          label={dgettext("schemas", "raw_content")}
          autocomplete="off"
          rows="10"
          phx-debounce="blur"
          required
        />
        <:actions>
          <.button>
            <%= dgettext("schemas", "save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{schema: schema} = assigns, socket) do
    latest_version = schema |> Map.get(:schema_versions) |> Enum.at(0)
    changeset = schema |> flatten_schema() |> change_schema()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:latest_is_in_draft?, latest_version.status == :draft)
     |> assign_new(:form, fn ->
       to_form(changeset, as: "schema")
     end)}
  end

  @impl true
  def handle_event("validate", %{"schema" => schema_params}, socket) do
    changeset = socket.assigns.schema |> flatten_schema() |> change_schema(schema_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "schema"))}
  end

  def handle_event("save", %{"schema" => schema_params}, socket) do
    schema_params = complete_schema(schema_params, socket)

    save_schema(socket, socket.assigns.action, schema_params)
  end

  defp save_schema(socket, :edit, schema_params) do
    case Schemas.update_schema(socket.assigns.schema, schema_params) do
      {:ok, %{update_schema: schema}} ->
        notify_parent({:saved, schema})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("schemas", "update_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, :update_schema, changeset, _} ->
        {:noreply,
         socket
         |> assign(form: to_form(changeset, action: :validate))
         |> put_flash(:error, dgettext("schemas", "update_failed"))}

      {:error, :create_schema_version, _, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schema_versions", "create_failed"))}

      {:error, :update_schema_version, _, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schema_versions", "update_failed"))}
    end
  end

  defp save_schema(socket, :new, schema_params) do
    case Schemas.create_schema(schema_params) do
      {:ok, schema} ->
        notify_parent({:saved, schema})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("schemas", "creation_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schemas", "creation_failed"))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp flatten_schema(%Schema{} = schema) do
    latest_version =
      schema.schema_versions
      |> Enum.at(0)

    content =
      if is_nil(latest_version.content),
        do: %{},
        else:
          get_in(latest_version.content, [
            "properties",
            "credentialSubject",
            "properties",
            "content"
          ])

    description =
      if is_nil(latest_version.content),
        do: nil,
        else: Map.get(latest_version.content, "description")

    %{
      title: schema.title,
      description: description,
      content: content
    }
  end

  defp change_schema(schema, attrs \\ %{}) do
    types = %{
      title: :string,
      description: :string,
      content: :map,
    }

    attrs =
      with true <- is_binary(attrs["content"]),
           {:ok, decoded_value} <- Jason.decode(attrs["content"]) do
        Map.put(attrs, "content", decoded_value)
      else
        _ -> attrs
      end

    {schema, types}
    |> Ecto.Changeset.cast(attrs, [:title, :description, :content])
    |> Ecto.Changeset.validate_required([:title, :content], message: gettext("field_required"))
    |> Ecto.Changeset.validate_length(:title,
      min: 2,
      max: 50,
      message: dgettext("schemas", "title_length %{max} %{min}", min: 2, max: 50)
    )
    |> Ecto.Changeset.validate_length(:description,
      min: 2,
      max: 255,
      message: dgettext("schemas", "title_length %{max} %{min}", min: 2, max: 255)
    )
  end

  defp complete_schema(schema_params, socket) do
    decoded = schema_params |> Map.get("content") |> Jason.decode!()
    schema_params = Map.put(schema_params, "content", decoded)

    Schemas.complete_schema(
      schema_params,
      socket.assigns.schema,
      socket.assigns.current_user
    )
  end
end

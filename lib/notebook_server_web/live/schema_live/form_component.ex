defmodule NotebookServerWeb.SchemaLive.FormComponent do
  alias NotebookServer.Schemas
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.info_banner
        :if={!@latest_is_in_draft?}
        content={dgettext("schemas", "latest_is_not_in_draft")}
        variant="warn"
      />
      <.simple_form
        for={@form}
        id="schema-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="text"
          field={@form[:title]}
          label={dgettext("schemas", "title")}
          placeholder={dgettext("schemas", "title_placeholder")}
          phx-debounce="blur"
          required
        />
        <.inputs_for :let={schema_version_form} field={@form[:schema_versions]}>
          <.input
            type="textarea"
            rows="2"
            field={schema_version_form[:description]}
            label={dgettext("schemas", "description")}
            placeholder={dgettext("schemas", "description_placeholder")}
            phx-debounce="blur"
          />
          <.input
            type="select"
            field={schema_version_form[:platform]}
            label={dgettext("schemas", "platform")}
            phx-debounce="blur"
            options={[
              {"web2", "web2"},
              {"web3", "web3"}
            ]}
          />
          <.inputs_for :let={schema_content_form} field={schema_version_form[:content]}>
            <.inputs_for :let={properties_form} field={schema_content_form[:properties]}>
              <.inputs_for :let={credential_subject_form} field={properties_form[:credential_subject]}>
                <.inputs_for :let={props_form} field={credential_subject_form[:properties]}>
                  <.input
                    type="textarea"
                    field={props_form[:raw]}
                    label={dgettext("schemas", "raw_content")}
                    autocomplete="off"
                    rows="10"
                    phx-debounce="blur"
                    required
                  />
                </.inputs_for>
              </.inputs_for>
            </.inputs_for>
          </.inputs_for>
        </.inputs_for>
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

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:latest_is_in_draft?, latest_version.status == :draft)
     |> assign_new(:form, fn ->
       to_form(Schemas.change_schema(schema))
     end)}
  end

  @impl true
  def handle_event("validate", %{"schema" => schema_params}, socket) do
    schema_params = socket |> complete_schema(schema_params)

    changeset =
      Schemas.change_schema(socket.assigns.schema, schema_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"schema" => schema_params}, socket) do
    schema_params = socket |> complete_schema(schema_params)

    save_schema(socket, socket.assigns.action, schema_params)
  end

  defp save_schema(socket, :edit, schema_params) do
    case Schemas.update_schema(socket.assigns.schema, schema_params) do
      {:ok, schema, schema} ->
        notify_parent({:saved, schema, schema})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("schemas", "update_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset, _} ->
        {:noreply, assign(socket, form: to_form(changeset))}
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

      {:error, changeset} ->
        IO.inspect(changeset)

        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> put_flash(:error, dgettext("schemas", "creation_failed"))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  def complete_schema(socket, schema) do
    title = schema |> Map.get("title")
    description = schema |> Map.get("description")

    properties_partial =
      if description != "",
        do: %{"title" => %{"const" => title}, "description" => %{"const" => description}},
        else: %{"title" => %{"const" => title}}

    properties =
      schema
      |> get_in(["schema_versions", "0", "content", "properties"])
      |> Map.merge(properties_partial)

    content =
      schema
      |> get_in(["schema_versions", "0", "content"])
      |> Map.merge(%{
        "title" => title,
        "description" => description,
        "properties" => properties
      })

    zero =
      schema
      |> get_in(["schema_versions", "0"])
      |> Map.merge(%{
        "user_id" => socket.assigns.current_user.org_id,
        "public_id" => Ecto.UUID.generate(),
        "version" => 0,
        "content" => content
      })

    schema
    |> Map.merge(%{
      "org_id" => socket.assigns.current_user.org_id,
      "public_id" => Ecto.UUID.generate(),
      "schema_versions" => %{"0" => zero}
    })
  end
end

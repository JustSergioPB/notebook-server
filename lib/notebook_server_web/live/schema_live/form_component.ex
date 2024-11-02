defmodule NotebookServerWeb.SchemaLive.FormComponent do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Schemas
  alias NotebookServer.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.info_banner
        :if={@schema_version.status != :draft}
        content={gettext("schema_is_not_draft_edit_will_create_new_draft")}
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
          label={gettext("title")}
          placeholder={gettext("title_placeholder")}
          phx-debounce="blur"
          required
        />
        <.input
          type="textarea"
          rows="2"
          field={@form[:description]}
          label={gettext("description")}
          placeholder={gettext("description_placeholder")}
          phx-debounce="blur"
        />
        <.input
          type="select"
          field={@form[:platform]}
          label={gettext("platform")}
          phx-debounce="blur"
          options={[
            {"web2", "web2"},
            {"web3", "web3"}
          ]}
        />
        <.input
          type="textarea"
          field={@form[:raw_content]}
          label={gettext("raw_content")}
          autocomplete="off"
          rows="10"
          phx-debounce="blur"
          required
        />
        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{schema_version: schema_version} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Schemas.change_schema_version(schema_version))
     end)}
  end

  @impl true
  def handle_event("validate", %{"schema_version" => schema_version_params}, socket) do
    changeset =
      Schemas.change_schema_version(socket.assigns.schema_version, schema_version_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"schema_version" => schema_version_params}, socket) do
    schema_version_params =
      schema_version_params
      |> Map.merge(%{
        "org_id" => socket.assigns.current_user.org_id,
        "user_id" => socket.assigns.current_user.id
      })

    save_schema(socket, socket.assigns.action, schema_version_params)
  end

  defp save_schema(socket, :edit, schema_version_params) do
    case Schemas.update_schema(socket.assigns.schema_version, schema_version_params) do
      {:ok, schema, schema_version} ->
        notify_parent({:saved, schema, schema_version})

        {:noreply,
         socket
         |> put_flash(:info, gettext("schema_updated_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset, _message} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_schema(socket, :new, schema_version_params) do
    case Schemas.create_schema(schema_version_params) do
      {:ok, schema, schema_version} ->
        notify_parent({:saved, schema, schema_version})

        {:noreply,
         socket
         |> put_flash(:info, gettext("schema_created_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset, message} ->
        {:noreply,
         socket
         |> assign(:form, to_form(changeset))
         |> put_flash(:error, message)}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

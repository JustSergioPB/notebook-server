defmodule NotebookServerWeb.SchemaLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Credentials
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="schema-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="textarea"
          field={@form[:context]}
          label={gettext("context")}
          autocomplete="off"
          rows="15"
          value={Jason.encode!(@form[:context].value, pretty: true)}
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
  def update(%{schema: schema} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Credentials.change_schema(schema))
     end)}
  end

  @impl true
  def handle_event("validate", %{"schema" => schema_params}, socket) do
    changeset = Credentials.change_schema(socket.assigns.schema, schema_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"schema" => schema_params}, socket) do
    save_schema(socket, socket.assigns.action, schema_params)
  end

  defp save_schema(socket, :edit, schema_params) do
    case Credentials.update_schema(socket.assigns.schema, schema_params) do
      {:ok, schema} ->
        notify_parent({:saved, schema})

        {:noreply,
         socket
         |> put_flash(:info, gettext("schema_updated_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_schema(socket, :new, schema_params) do
    org_id = socket.assigns.current_user.org_id
    schema_params = Map.put(schema_params, "org_id", org_id)

    case Credentials.create_schema(schema_params) do
      {:ok, schema} ->
        notify_parent({:saved, schema})

        {:noreply,
         socket
         |> put_flash(:info, gettext("schema_created_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

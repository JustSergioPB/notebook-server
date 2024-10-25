defmodule NotebookServerWeb.CredentialLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Schemas
  alias NotebookServer.Credentials
  alias NotebookServer.Accounts.User
  alias NotebookServerWeb.Live.Components.SelectSearch
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
        id="select-form"
        phx-submit="next"
      >
        <.live_component
          field={@select_form[:schema]}
          id={@select_form[:schema].id}
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
        for={@form}
        id="credential-form"
        class={if @step == 1, do: "flex", else: "hidden"}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="next"
      >
        <:actions>
          <.button variant="outline" disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("back") %>
          </.button>
          <.button disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{credential: _credential} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> update_schema_options()
     |> assign(:step, 0)
     |> assign_new(:select_form, fn ->
       to_form(%{"schema" => %{}})
     end)
     |> assign_new(:form, fn -> to_form(%{}) end)}
  end

  @impl true
  def handle_event("autocomplete_schemas", %{"query" => query}, socket) do
    IO.inspect(query)
    {:noreply, update_schema_options(socket, query)}
  end

  def handle_event("next", %{"search" => _search, "selected_schema" => selected_schema}, socket) do
    socket =
      if !is_nil(selected_schema) do
        assign(socket, :step, socket.assigns.step + 1)
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("save", %{"credential" => credential_params}, socket) do
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
        schema |> Schemas.map_to_row() |> Map.merge(%{text: schema.title})
      end)

    assign(socket, schema_options: options)
  end
end

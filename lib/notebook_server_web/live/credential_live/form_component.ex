defmodule NotebookServerWeb.CredentialLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Schemas
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
      <div class="space-y-6">
        <.simple_form for={@search_form} id="search-form" phx-target={@myself} phx-submit="search">
          <div class="flex items-end gap-2 w-full">
            <.input
              field={@search_form[:search]}
              type="text"
              label={gettext("search_schema")}
              placeholder={gettext("schema_placeholder")}
              class="flex-1"
              required
            />
            <.tooltip text={gettext("search")}>
              <.button
                size="icon"
                icon="search"
                class="p-3"
                disabled={!User.can_use_platform?(@current_user)}
              >
                <%= gettext("search") %>
              </.button>
            </.tooltip>
          </div>
        </.simple_form>
        <.simple_form for={@select_form} id="select-form" phx-target={@myself} phx-submit="next">
          <div>
            <.label class="mb-2"><%= gettext("schema") %></.label>
            <div class="h-64">
              <ul :if={length(@schemas) > 0} class="h-full">
                <li :for={schema <- @schemas}>
                  <%= schema.title %>
                </li>
              </ul>
              <div class="h-full flex flex-col gap-2 items-center justify-center">
                <p class="text-sm font-bold"><%= gettext("no_results_found") %></p>
                <p class="text-sm font-regular">
                  <%= gettext("no_query_match %{term}",
                    term: Phoenix.HTML.Form.input_value(@search_form, "search")
                  ) %>
                </p>
                <.button
                  variant="outline"
                  size="sm"
                  type="button"
                  class="mt-4"
                  phx-target={@myself}
                  phx-click="clear-search"
                >
                  <%= gettext("clear_search") %>
                </.button>
              </div>
            </div>
          </div>
          <:actions>
            <.button disabled={!User.can_use_platform?(@current_user)}>
              <%= gettext("next") %>
            </.button>
          </:actions>
        </.simple_form>
      </div>
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
     |> assign(:schemas, [])
     |> assign(:step, 0)
     |> assign_new(:search_form, fn ->
       to_form(%{"search" => ""})
     end)
     |> assign_new(:select_form, fn ->
       to_form(%{"option" => nil})
     end)}
  end

  @impl true

  def handle_event("search", %{"search" => search}, socket) do
    opts = org_filter(socket) ++ [title: search, status: :published]

    {:noreply,
     socket
     |> assign(:schemas, Schemas.list_schemas(opts))
     |> assign(:search_form, to_form(%{"search" => search}))}
  end

  def handle_event("clear-search", _value, socket) do
    {:noreply,
     socket
     |> assign(:schemas, [])
     |> assign(:search_form, to_form(%{"search" => ""}))}
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
end

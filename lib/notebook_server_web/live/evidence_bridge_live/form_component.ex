defmodule NotebookServerWeb.EvidenceBridgeLive.FormComponent do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Schemas
  alias NotebookServer.Bridges
  alias NotebookServer.Accounts.User
  alias NotebookServerWeb.Components.SelectSearch

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="space-y-6">
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="evidence-bridge-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.live_component
          field={@form[:bridge_id]}
          id={@form[:bridge_id].id}
          module={SelectSearch}
          label={gettext("search_bridges")}
          options={@bridge_options}
          placeholder={gettext("tag_placeholder") <> "..."}
          autocomplete="autocomplete_bridges"
          target="#evidence-bridge-form"
        >
          <:option :let={bridge}>
            <p class="uppercase"><%= bridge.text %></p>
          </:option>
        </.live_component>
        <.live_component
          field={@form[:schema_id]}
          id={@form[:schema_id].id}
          module={SelectSearch}
          label={gettext("search_schema")}
          options={@schema_version_options}
          placeholder={gettext("title_placeholder") <> "..."}
          autocomplete="autocomplete_schemas"
          target="#evidence-bridge-form"
        >
          <:option :let={schema}>
            <.schema_version_option schema={schema} />
          </:option>
        </.live_component>
        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}><%= gettext("save") %></.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{evidence_bridge: evidence_bridge} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> update_bridge_options()
     |> update_schema_options()
     |> assign_new(:form, fn ->
       to_form(Bridges.change_evidence_bridge(evidence_bridge))
     end)}
  end

  @impl true
  def handle_event("autocomplete_schemas", %{"query" => query}, socket) do
    {:noreply, update_schema_options(socket, query)}
  end

  def handle_event("autocomplete_bridges", %{"query" => query}, socket) do
    {:noreply, update_schema_options(socket, query)}
  end

  def handle_event("validate", %{"evidence_bridge" => evidence_bridge_params}, socket) do
    evidence_bridge_params =
      evidence_bridge_params |> Map.put("org_id", socket.assigns.current_user.org_id)

    changeset =
      Bridges.change_evidence_bridge(socket.assigns.evidence_bridge, evidence_bridge_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"evidence_bridge" => evidence_bridge_params}, socket) do
    evidence_bridge_params =
      evidence_bridge_params |> Map.put("org_id", socket.assigns.current_user.org_id)

    save_bridge(socket, socket.assigns.action, evidence_bridge_params)
  end

  defp save_bridge(socket, :edit, evidence_bridge_params) do
    case Bridges.update_evidence_bridge(socket.assigns.evidence_bridge, evidence_bridge_params) do
      {:ok, evidence_bridge} ->
        notify_parent({:saved, evidence_bridge})

        {:noreply,
         socket
         |> put_flash(:info, gettext("bridge_update_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bridge(socket, :new, evidence_bridge_params) do
    case Bridges.create_evidence_bridge(evidence_bridge_params) do
      {:ok, evidence_bridge} ->
        notify_parent({:saved, evidence_bridge})

        {:noreply,
         socket
         |> put_flash(:info, gettext("bridge_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp update_schema_options(socket, query \\ "") do
    options =
      Schemas.list_schema_versions(title: query, status: :published)
      |> Enum.map(fn schema_version ->
        schema_version
        |> Map.merge(%{
          text: schema_version.title,
          id: schema_version.schema_id,
          name: schema_version.title
        })
      end)

    assign(socket, schema_version_options: options)
  end

  defp update_bridge_options(socket, query \\ "") do
    options =
      Bridges.list_bridges(tag: query)
      |> Enum.map(fn bridge ->
        bridge
        |> Map.merge(%{
          text: bridge.tag,
          name: bridge.tag
        })
      end)

    assign(socket, bridge_options: options)
  end
end

defmodule NotebookServerWeb.Components.FormBuilder do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-1">
      <.label for={@id}><%= @label %></.label>
      <input type="hidden" id={@id} name={@name} value="" />
      <div class="space-y-4">
        <div
          :for={{row_index, row} <- Enum.with_index(@rows, fn elem, index -> {index, elem} end)}
          class="flex items-center gap-4"
        >
          <div
            :for={{cell_index, cell} <- Enum.with_index(row, fn elem, index -> {index, elem} end)}
            class="flex-1 flex items-center justify-between rounded-md border border-slate-300 bg-white sm:text-sm px-3 py-2"
          >
            <%= cell["title"] %>
            <div class="flex items-center gap-1">
              <.tooltip text={dgettext("schemas", "edit_cell")}>
                <.button
                  type="button"
                  size="icon"
                  icon="pencil"
                  variant="ghost"
                  phx-value-row={row_index}
                  phx-click="edit_cell"
                  phx-target={@myself}
                >
                  <%= dgettext("schemas", "edit_cell") %>
                </.button>
              </.tooltip>
              <.tooltip text={dgettext("schemas", "remove_cell")}>
                <.button
                  type="button"
                  size="icon"
                  icon="trash"
                  variant="ghost"
                  phx-value-row={row_index}
                  phx-value-elem={cell_index}
                  phx-click="remove_cell"
                  phx-target={@myself}
                >
                  <%= dgettext("schemas", "remove_cell") %>
                </.button>
              </.tooltip>
            </div>
          </div>
          <.tooltip text={dgettext("schemas", "add_cell")}>
            <.button
              type="button"
              size="icon"
              class="!rounded-full p-3"
              icon="plus-circle"
              phx-value-row={row_index}
              phx-click="add_cell"
              phx-target={@myself}
            >
              <%= dgettext("schemas", "add_cell") %>
            </.button>
          </.tooltip>
        </div>
        <.button type="button" size="sm" icon="plus-circle" phx-click="add_row" phx-target={@myself}>
          <%= dgettext("schemas", "add_row") %>
        </.button>
      </div>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    %{field: field} = assigns

    socket =
      socket
      |> assign(assigns)
      |> assign(field: nil, id: assigns.id || field.id)
      |> assign(:errors, Enum.map(field.errors, &translate_error(&1)))
      |> assign_new(:name, fn -> field.name end)
      |> assign_new(:value, fn -> field.value end)
      |> assign(:rows, [])

    {:ok, socket}
  end

  @impl true

  def handle_event("add_cell", %{"row" => row_index}, socket) do
    {:noreply,
     socket
     |> assign(
       :rows,
       socket.assigns.rows
       |> List.update_at(String.to_integer(row_index), fn row ->
         row ++
           [
             %{
               "type" => "string",
               "title" => dgettext("schemas", "new_field"),
               "examples" => [dgettext("schemas", "new_field")]
             }
           ]
       end)
     )}
  end

  def handle_event("remove_cell", %{"row" => row_index, "elem" => elem_index}, socket) do
    {:noreply,
     socket
     |> assign(
       :rows,
       socket.assigns.rows
       |> List.update_at(String.to_integer(row_index), fn row ->
         row |> List.delete_at(String.to_integer(elem_index))
       end)
       |> Enum.filter(fn row -> row != [] end)
     )}
  end

  def handle_event("add_row", _, socket) do
    {:noreply,
     socket
     |> assign(
       :rows,
       socket.assigns.rows ++
         [
           [
             %{
               "type" => "string",
               "title" => dgettext("schemas", "new_field"),
               "examples" => [dgettext("schemas", "new_field")]
             }
           ]
         ]
     )}
  end
end

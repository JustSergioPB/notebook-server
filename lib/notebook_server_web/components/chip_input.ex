defmodule NotebookServerWeb.Components.ChipInput do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-1">
      <.label for={@id}><%= @label %></.label>
      <input type="hidden" id={@id} name={@name} value={Enum.join(@chips, "|")} />
      <div class="flex items-center gap-1">
        <input
          form="disabled"
          id={@id <> "_input"}
          type="text"
          autocomplete="off"
          placeholder={if is_binary(@placeholder), do: @placeholder, else: ""}
          phx-hook="Chip"
          phx-debounce="blur"
          class={[
            "block w-full rounded-md text-slate-900 focus:ring-1 focus:ring-indigo-500 sm:text-sm sm:leading-6 disabled:opacity-50",
            @errors == [] && "border-slate-300 focus:border-slate-400",
            @errors != [] && "border-rose-400 focus:border-rose-400"
          ]}
        />
        <.tooltip text={gettext("remove_chip")}>
          <.button
            type="button"
            size="icon"
            variant="ghost"
            icon="x"
            phx-click="clear"
            phx-target={@myself}
          >
            <%= gettext("remove_chip") %>
          </.button>
        </.tooltip>
      </div>
      <div className="flex flex-wrap items-center gap-1">
        <.badge
          :for={chip <- @chips}
          variant="primary"
          phx-value-chip={chip}
          phx-click="remove"
          phx-target={@myself}
        >
          <:label>
            <%= chip %>
          </:label>
        </.badge>
      </div>
      <.hint :if={@hint}><%= @hint %></.hint>
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
      |> assign(:chips, get_chips(field.value))

    {:ok, socket}
  end

  defp get_chips(field_value) when is_binary(field_value) do
    field_value |> String.split("|") |> Enum.filter(fn chip -> chip != "" end)
  end

  defp get_chips(_), do: []

  @impl true
  def handle_event("clear", _, socket) do
    {:noreply, assign(socket, :chips, [])}
  end

  def handle_event("add", %{"value" => value}, socket) when value != "" do
    {:noreply, socket |> assign(:chips, [value | socket.assigns.chips])}
  end

  def handle_event("remove", %{"chip" => value}, socket) do
    {:noreply,
     socket |> assign(:chips, socket.assigns.chips |> Enum.filter(fn chip -> chip != value end))}
  end
end

defmodule NotebookServerWeb.Components.SelectSearch do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div
      phx-feedback-for={@name}
      phx-hook="Select"
      autocomplete={@autocomplete}
      id={@id}
      target={@target}
    >
      <.label for={@id}><%= @label %></.label>
      <div class="relative">
        <div class="relative">
          <input
            type="hidden"
            id={@id <> "_value_input"}
            name={@name}
            value={if @selected, do: @selected.id}
          />
          <input
            form="disabled"
            id={@id <> "_input"}
            type="text"
            autocomplete="off"
            value={if @selected, do: @selected.name, else: ""}
            placeholder={if is_binary(@placeholder), do: @placeholder, else: ""}
            class={[
              "mt-2 block w-full rounded-lg text-slate-900 focus:ring-0 sm:text-sm sm:leading-6",
              "phx-no-feedback:border-slate-300 phx-no-feedback:focus:border-slate-400",
              @errors == [] && "border-slate-300 focus:border-slate-400",
              @errors != [] && "border-rose-400 focus:border-rose-400"
            ]}
          />
          <div id={@id <> "_loader"} class="absolute right-2 top-0 bottom-0 flex items-center hidden">
            <Lucide.loader class="block h-4 w-4 animate-spin text-slate-600" />
          </div>
        </div>
        <div
          id={@id <> "_select"}
          class="absolute w-full top-[100%] border border-slate-300 rounded shadow-md my-2 bg-white hidden z-50"
        >
          <div class="relative max-h-[200px] overflow-y-auto">
            <%= if Enum.empty?(@options) do %>
              <div class="p-2 h-64 flex items-center justify-center">
                <p class="text-sm font-bold flex items-center justify-center">
                  <%= gettext("no_results") %>
                </p>
              </div>
            <% else %>
              <%= for option <- @options do %>
                <div
                  class="cursor-default hover:bg-slate-100 hover:cursor-pointer text-sm flex flex-col items-start space-y p-2"
                  data-id={option.id}
                  data-text={option.text}
                >
                  <%= render_slot(@option, option) %>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
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

    selected = Enum.find(socket.assigns.options, &(&1.id == field.value))
    socket = socket |> assign(:selected, selected)

    {:ok, socket}
  end
end

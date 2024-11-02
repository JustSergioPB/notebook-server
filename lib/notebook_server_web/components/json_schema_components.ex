defmodule NotebookServerWeb.JsonSchemaComponents do
  use Phoenix.Component
  use Gettext, backend: NotebookServerWeb.Gettext
  alias NotebookServerWeb.CoreComponents

  attr :field, :atom, required: true
  attr :schema, :map, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def json_schema_node(%{schema: %{"type" => "object"}, field: field} = assigns) do
    assigns = assigns |> assign(:as, String.to_atom(field.id))

    ~H"""
    <div class={["space-y-2", @class]} id={@as}>
      <p :if={@schema["title"]} class="font-semibold"><%= @schema["title"] %></p>
      <.inputs_for :let={subform} field={@field}>
        <%= for {key, sub_schema} <-  @schema["properties"] do %>
          <.json_schema_node field={subform[key]} schema={sub_schema} />
        <% end %>
      </.inputs_for>
    </div>
    """
  end

  def json_schema_node(%{schema: %{"type" => "array"} = schema, field: field} = assigns) do
    items_schema = Map.get(schema, "items")

    assigns =
      assigns
      |> assign(:items_schema, items_schema)
      |> assign(:as, String.to_atom(field.id))

    ~H"""
    <div class={["space-y-2", @class]} id={@as}>
      <div class="flex items-center justify-between">
        <p :if={@schema["title"]} class="font-semibold"><%= @schema["title"] %></p>
        <CoreComponents.button type="button" size="sm" icon="plus-circle">
          <%= gettext("add") %>
        </CoreComponents.button>
      </div>
      <ul>
        <.inputs_for field={@field}>
          <li class="flex items-start gap-2 justify-between">
            <.json_schema_node field={@field} schema={@items_schema} class="flex-1" />
            <CoreComponents.button
              type="button"
              variant="ghost"
              size="icon"
              icon="trash"
              class="shrink-0"
            >
              <%= gettext("delete") %>
            </CoreComponents.button>
          </li>
        </.inputs_for>
      </ul>
    </div>
    """
  end

  def json_schema_node(%{schema: %{"enum" => enum} = schema} = assigns) do
    label = Map.get(schema, "title")
    props = if is_binary(label), do: Map.new() |> Map.put(:label, label), else: Map.new()
    props = props |> Map.put(:type, "select") |> Map.put(:options, enum)

    assigns =
      assigns
      |> assign(:props, props)

    ~H"""
    <CoreComponents.input id={@field.id} field={@field} {@props} {@rest} phx-debounce="blur" />
    """
  end

  def json_schema_node(%{schema: %{"type" => type} = schema} = assigns)
      when type in ["string", "integer", "number", "boolean"] do
    label = Map.get(schema, "title")
    examples = schema |> Map.get("examples")

    placeholder = if is_list(examples), do: examples |> Enum.at(0) |> to_string(), else: ""

    props = if is_binary(label), do: Map.new() |> Map.put(:label, label), else: Map.new()
    props = props |> Map.put(:placeholder, placeholder)

    props = Map.merge(props, get_props(schema))

    assigns =
      assigns
      |> assign(:props, props)

    ~H"""
    <CoreComponents.input id={@field.id} field={@field} {@props} {@rest} phx-debounce="blur" />
    """
  end

  defp get_props(%{"type" => "string"} = schema) do
    minLength = Map.get(schema, "minLength")
    maxLength = Map.get(schema, "maxLength")
    pattern = Map.get(schema, "pattern")
    format = Map.get(schema, "format")

    type =
      case format do
        "email" -> "email"
        "date-time" -> "datetime-local"
        "date" -> "date"
        "time" -> "time"
        "uri" -> "url"
        nil -> "text"
        _ -> "text"
      end

    props = Map.new() |> Map.put(:type, type)

    props =
      if is_integer(minLength),
        do: props |> Map.put(:minlength, minLength),
        else: props

    props =
      if is_integer(maxLength),
        do: props |> Map.put(:maxlength, maxLength),
        else: props

    props =
      if is_binary(pattern), do: props |> Map.put(:pattern, pattern), else: props

    props
  end

  defp get_props(%{"type" => type} = schema)
       when type in ["integer", "number"] do
    minimum = Map.get(schema, "minimum")
    maximum = Map.get(schema, "maximum")
    multiple_of = Map.get(schema, "multipleOf")
    exclusive_minimum = Map.get(schema, "exclusiveMinimum")
    exclusive_maximum = Map.get(schema, "exclusiveMaximum")

    step =
      cond do
        multiple_of -> to_string(multiple_of)
        type == "number" -> "any"
        true -> "1"
      end

    min =
      cond do
        exclusive_minimum -> exclusive_minimum + if type == "integer", do: 1, else: 0.000001
        minimum -> minimum
        true -> nil
      end

    max =
      cond do
        exclusive_maximum -> exclusive_maximum - if type == "integer", do: 1, else: 0.000001
        maximum -> maximum
        true -> nil
      end

    props = Map.new() |> Map.put(:type, "number") |> Map.put(:type, type) |> Map.put(:step, step)
    props = if is_integer(min), do: props |> Map.put(:min, min), else: props
    props = if is_integer(max), do: props |> Map.put(:max, max), else: props

    props
  end

  defp get_props(%{"type" => "boolean"}) do
    Map.new() |> Map.put(:type, "checkbox")
  end
end

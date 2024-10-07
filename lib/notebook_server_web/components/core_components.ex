defmodule NotebookServerWeb.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At first glance, this module may seem daunting, but its goal is to provide
  core building blocks for your application, such as modals, tables, and
  forms. The components consist mostly of markup and are well-documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS
  use Gettext, backend: NotebookServerWeb.Gettext

  @doc """
  Renders a modal.

  ## Examples

      <.modal id="confirm-modal">
        This is a modal.
      </.modal>

  JS commands may be passed to the `:on_cancel` to configure
  the closing/cancel event, for example:

      <.modal id="confirm" on_cancel={JS.navigate(~p"/posts")}>
        This is another modal.
      </.modal>

  """
  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, JS, default: %JS{}
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div
        id={"#{@id}-bg"}
        class="bg-slate-50/90 fixed inset-0 transition-opacity"
        aria-hidden="true"
      />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={"#{@id}-title"}
        aria-describedby={"#{@id}-description"}
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <.focus_wrap
              id={"#{@id}-container"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-slate-700/10 ring-slate-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div class="absolute top-6 right-5">
                <button
                  phx-click={JS.exec("data-cancel", to: "##{@id}")}
                  type="button"
                  class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                  aria-label={gettext("close")}
                >
                  <.icon name="hero-x-mark-solid" class="h-5 w-5" />
                </button>
              </div>
              <div id={"#{@id}-content"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error")}
        phx-connected={hide("#client-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error")}
        phx-connected={hide("#server-error")}
        hidden
      >
        <%= gettext("Hang in there while we get back on track") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :class, :string, default: nil, doc: "the class to apply to the form"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest} class={["space-y-4 flex flex-col", @class]}>
      <div class="flex-1 space-y-4">
        <%= render_slot(@inner_block, f) %>
      </div>
      <div :for={action <- @actions} class="flex items-center justify-between gap-6 last:pt-6">
        <%= render_slot(action, f) %>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :type, :string, default: nil
  attr :variant, :string, default: "primary"
  attr :size, :string, default: "md"
  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg flex items-center justify-center group",
        "text-sm font-semibold leading-6",
        @size == "lg" && "py-3 px-4 gap-2",
        @size == "md" && "py-2 px-3 gap-2",
        @size == "sm" && "py-1 px-2 gap-2",
        @size == "icon" && "p-2",
        @variant == "primary" && "bg-slate-900 hover:bg-slate-700 text-white active:text-white/80",
        @variant == "outline" &&
          "bg-transparent shadow-sm border border-slate-200 hover:bg-slate-100",
        @variant == "ghost" && "bg-transparent shadow-sm hover:bg-slate-100",
        @class
      ]}
      {@rest}
    >
      <Lucide.render :if={@icon} icon={@icon} class="w-4 h-4 group-[.phx-submit-loading]:hidden" />
      <Lucide.loader class="w-4 h-4 animate-spin hidden group-[.phx-submit-loading]:block" />
      <span class={[@size == "icon" && "sr-only"]}><%= render_slot(@inner_block) %></span>
    </button>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Send!</.button>
      <.button phx-click="go" class="ml-2">Send!</.button>
  """
  attr :variant, :string, default: "primary"
  attr :size, :string, default: "md"
  attr :class, :string, default: nil
  attr :patch, :string, default: nil
  attr :navigate, :string, default: nil
  attr :icon, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)

  slot :inner_block, required: true

  def button_link(assigns) do
    ~H"""
    <.link
      patch={@patch}
      navigate={@navigate}
      class={[
        "rounded-lg flex items-center justify-center group",
        "text-sm font-semibold leading-6",
        @size == "lg" && "py-3 px-4 gap-2",
        @size == "md" && "py-2 px-3 gap-2",
        @size == "sm" && "py-1 px-2 gap-2",
        @size == "icon" && "p-2",
        @variant == "primary" && "bg-slate-900 hover:bg-slate-700 text-white active:text-white/80",
        @variant == "outline" &&
          "bg-transparent shadow-sm border border-slate-200 hover:bg-slate-100",
        @variant == "ghost" && "bg-transparent shadow-sm hover:bg-slate-100",
        @class
      ]}
      {@rest}
    >
      <Lucide.render :if={@icon} icon={@icon} class="w-4 h-4" />
      <span class={[@size == "icon" && "sr-only"]}><%= render_slot(@inner_block) %></span>
    </.link>
    """
  end

  @doc """
  Renders an input with label and error messages.

  A `Phoenix.HTML.FormField` may be passed as argument,
  which is used to retrieve the input name, id, and values.
  Otherwise all attributes may be passed explicitly.

  ## Types

  This function accepts all HTML input types, considering that:

    * You may also set `type="select"` to render a `<select>` tag

    * `type="checkbox"` is used exclusively to render boolean values

    * For live file uploads, see `Phoenix.Component.live_file_input/1`

  See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input
  for more information. Unsupported types, such as hidden and radio,
  are best written directly in your templates.

  ## Examples

      <.input field={@form[:email]} type="email" />
      <.input name="my-input" errors={["oh no!"]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :class, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               range search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div>
      <label class="flex items-center gap-2 text-sm leading-6 text-slate-600">
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class="rounded border-slate-300 text-slate-900 focus:ring-0"
          {@rest}
        />
        <%= @label %>
      </label>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div>
      <.label :if={@label} class="mb-2" for={@id}><%= @label %></.label>
      <select
        id={@id}
        name={@name}
        class="block w-full rounded-md border border-gray-300 bg-white shadow-sm focus:border-slate-400 focus:ring-0 sm:text-sm"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value=""><%= @prompt %></option>
        <%= Phoenix.HTML.Form.options_for_select(@options, @value) %>
      </select>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div>
      <.label for={@id}><%= @label %></.label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "mt-2 block w-full rounded-lg text-slate-900 focus:ring-0 sm:text-sm sm:leading-6 min-h-[6rem]",
          @errors == [] && "border-slate-300 focus:border-slate-400",
          @errors != [] && "border-rose-400 focus:border-rose-400"
        ]}
        {@rest}
      ><%= Phoenix.HTML.Form.normalize_value("textarea", @value) %></textarea>
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  # All other inputs text, datetime-local, url, password, etc. are handled here...
  def input(assigns) do
    ~H"""
    <div class={@class}>
      <.label for={@id}><%= @label %></.label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "mt-2 block w-full rounded-lg text-slate-900 focus:ring-0 sm:text-sm sm:leading-6 disabled:opacity-50",
          @errors == [] && "border-slate-300 focus:border-slate-400",
          @errors != [] && "border-rose-400 focus:border-rose-400",
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}><%= msg %></.error>
    </div>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label
      for={@for}
      class={[
        "block text-sm font-semibold leading-6 text-slate-800",
        @class
      ]}
    >
      <%= render_slot(@inner_block) %>
    </label>
    """
  end

  @doc """
  Generates a generic error message.
  """
  slot :inner_block, required: true

  def error(assigns) do
    ~H"""
    <p class="flex items-center gap-2 text-sm text-rose-600">
      <Lucide.alert_triangle class="h-4 w-4" />
      <%= render_slot(@inner_block) %>
    </p>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class={[@actions != [] && "flex items-center justify-between gap-4", @class]}>
      <div>
        <h1 class="text-2xl font-semibold leading-8 text-slate-800">
          <%= render_slot(@inner_block) %>
        </h1>
        <p :if={@subtitle != []} class="text-sm leading-6 text-slate-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :class, :string, default: nil
  attr :icon, :string, default: nil
  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def page_header(assigns) do
    ~H"""
    <header class={[
      "flex items-center justify-between gap-4 p-6 border-b border-slate-200",
      @class
    ]}>
      <div>
        <span class="flex items-center">
          <Lucide.render :if={@icon} icon={@icon} class="h-5 w-5 mr-2" />
          <h1 class="text-lg font-bold text-slate-800">
            <%= render_slot(@inner_block) %>
          </h1>
        </span>
        <p :if={@subtitle != []} class="text-sm leading-6 text-slate-600">
          <%= render_slot(@subtitle) %>
        </p>
      </div>
      <div class="flex-none"><%= render_slot(@actions) %></div>
    </header>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def page_content(assigns) do
    ~H"""
    <section class={["p-6 flex flex-col flex-1 space-y-6", @class]}>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  @doc ~S"""
  Renders a table with generic styling.

  ## Examples

      <.table id="users" rows={@users}>
        <:col :let={user} label="id"><%= user.id %></:col>
        <:col :let={user} label="username"><%= user.username %></:col>
      </.table>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil, doc: "the function for generating the row id"
  attr :row_click, :any, default: nil, doc: "the function for handling phx-click on each row"
  attr :class, :string, default: nil, doc: "the class for the table"

  attr :row_item, :any,
    default: &Function.identity/1,
    doc: "the function for mapping each row before calling the :col and :action slots"

  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={[
      "overflow-y-auto px-4 sm:overflow-visible sm:px-0 border border-slate-200 rounded-lg",
      @class
    ]}>
      <table class="w-full h-fullflex flex-col">
        <thead class="bg-slate-100 border-b border-slate-200 w-full">
          <tr>
            <th :for={col <- @col} class="text-sm text-left text-slate-700 p-3 font-semibold">
              <%= col[:label] %>
            </th>
            <th :if={@action != []}>
              <span class="sr-only"><%= gettext("Actions") %></span>
            </th>
          </tr>
        </thead>
        <tbody
          id={@id}
          phx-update={match?(%Phoenix.LiveView.LiveStream{}, @rows) && "stream"}
          class="flex-1 divide-y divide-slate-100 w-full min-h-0 overflow-y-auto"
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="h-[10%]">
            <td
              :for={{col, _i} <- Enum.with_index(@col)}
              phx-click={@row_click && @row_click.(row)}
              class="p-3 text-sm text-slate-700"
            >
              <%= render_slot(col, @row_item.(row)) %>
            </td>
            <td :if={@action != []} class="flex items-center justify-end gap-2 p-3">
              <span :for={action <- @action}>
                <%= render_slot(action, @row_item.(row)) %>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr :page, :integer, required: true
  attr :total_pages, :integer, required: true

  def pagination(assigns) do
    ~H"""
    <div class="flex items-center justify-end gap-8">
      <div class="flex items-center gap-2 text-sm font-semibold">
        <span><%= gettext("rows_per_page") %>:</span>
        <.input name="rows_per_page" value="10" type="select" options={["10", "25", "50", "100"]} />
      </div>
      <p class="text-sm font-semibold">
        <%= gettext("page") %> <%= @page %> <%= gettext("of") %> <%= @total_pages %>
      </p>
      <div class="flex items-center gap-2">
        <.button_link size="icon" icon="chevrons-left" variant="outline">
          <%= gettext("last_page") %>
        </.button_link>
        <.button_link size="icon" icon="chevron-left" variant="outline">
          <%= gettext("previous_page") %>
        </.button_link>
        <.button_link size="icon" icon="chevron-right" variant="outline">
          <%= gettext("next_page") %>
        </.button_link>
        <.button_link size="icon" icon="chevrons-right" variant="outline">
          <%= gettext("first_page") %>
        </.button_link>
      </div>
    </div>
    """
  end

  @doc """
  Renders a data list.

  ## Examples

      <.list>
        <:item title="Title"><%= @post.title %></:item>
        <:item title="Views"><%= @post.views %></:item>
      </.list>
  """
  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class="mt-14">
      <dl class="-my-4 divide-y divide-slate-100">
        <div :for={item <- @item} class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
          <dt class="w-1/4 flex-none text-slate-500"><%= item.title %></dt>
          <dd class="text-slate-700"><%= render_slot(item) %></dd>
        </div>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back navigation link.

  ## Examples

      <.back navigate={~p"/posts"}>Back to posts</.back>
  """
  attr :navigate, :any, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link
        navigate={@navigate}
        class="text-sm font-semibold leading-6 text-slate-900 hover:text-slate-700"
      >
        <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
        <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).

  Heroicons come in three styles – outline, solid, and mini.
  By default, the outline style is used, but solid and mini may
  be applied by using the `-solid` and `-mini` suffix.

  You can customize the size and colors of the icons by setting
  width, height, and background color classes.

  Icons are extracted from the `deps/heroicons` directory and bundled within
  your compiled app.css by the plugin in your `assets/tailwind.config.js`.

  ## Examples

      <.icon name="hero-x-mark-solid" />
      <.icon name="hero-arrow-path" class="ml-1 w-3 h-3 animate-spin" />
  """
  attr :name, :string, required: true
  attr :class, :string, default: nil

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} />
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all transform ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js,
      to: selector,
      time: 200,
      transition:
        {"transition-all transform ease-in duration-200",
         "opacity-100 translate-y-0 sm:scale-100",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"}
    )
  end

  def show_modal(js \\ %JS{}, id) when is_binary(id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(
      to: "##{id}-bg",
      time: 300,
      transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"}
    )
    |> show("##{id}-container")
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-content")
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(
      to: "##{id}-bg",
      transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"}
    )
    |> hide("##{id}-container")
    |> JS.hide(to: "##{id}", transition: {"block", "block", "hidden"})
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(NotebookServerWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(NotebookServerWeb.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :href, :string, required: true
  attr :active, :boolean, default: false
  attr :method, :string, default: "get"

  def nav_link(assigns) do
    ~H"""
    <li>
      <.link
        href={@href}
        method={@method}
        class={[
          "flex items-center gap-2 text-sm text-slate-900 hover:bg-slate-100 p-2 rounded-md focus:bg-slate-100 outline-none focus:ring-1 focus:ring-slate-900 group",
          @active && "bg-slate-100"
        ]}
      >
        <Lucide.render icon={@icon} class="h-4 w-4 group-hover" />
        <%= @label %>
      </.link>
    </li>
    """
  end

  attr :class, :string, default: nil
  attr :name, :string, required: true
  attr :last_name, :string, required: true
  attr :email, :string, required: true
  attr :role, :string, required: true

  def user_badge(assigns) do
    ~H"""
    <div class={["flex items-center gap-4", @class]}>
      <div class={[
        "h-10 w-10 flex items-center justify-center rounded-md uppercase",
        @role == :admin && "bg-orange-100",
        @role == :org_admin && "bg-purple-100",
        @role == :user && "bg-blue-100"
      ]}>
        <Lucide.shield_plus :if={@role == :admin} class="h-5 w-5 text-orange-500" />
        <Lucide.shield :if={@role == :org_admin} class="h-5 w-5 text-purple-500" />
        <Lucide.pen_tool :if={@role == :user} class="h-5 w-5 text-blue-500" />
      </div>
      <div>
        <p class="text-sm text-slate-900"><%= @name %> <%= @last_name %></p>
        <p class="text-xs text-slate-500"><%= @email %></p>
      </div>
    </div>
    """
  end

  attr :variant, :string, default: "outline"
  attr :class, :string, default: nil

  slot :inner_block, required: true

  def status_badge(assigns) do
    ~H"""
    <div class={[
      "inline-flex items-center gap-2 rounded-lg px-3 py-1 text-sm",
      @variant == "primary" && "bg-slate-100 text-slate-700",
      @variant == "success" && "bg-green-100 text-green-700",
      @variant == "outline" && "border border-slate-200",
      @class
    ]}>
      <div class={[
        "h-2 w-2 rounded-full",
        @variant == "primary" && "bg-slate-900",
        @variant == "success" && "bg-green-700",
        @variant == "outline" && "bg-slate-200"
      ]}>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :role, :string, required: true
  attr :class, :string, default: nil
  slot :inner_block, required: true

  def role_badge(assigns) do
    ~H"""
    <div class={[
      "inline-flex items-center gap-2 rounded-lg px-3 py-1 text-sm",
      @role == :admin && "bg-orange-100 text-orange-700",
      @role == :org_admin && "bg-purple-100 text-purple-700",
      @role == :user && "bg-blue-100 text-blue-700",
      @class
    ]}>
      <Lucide.shield_plus :if={@role == :admin} class="h-4 w-4 text-orange-500" />
      <Lucide.shield :if={@role == :org_admin} class="h-4 w-4 text-purple-500" />
      <Lucide.pen_tool :if={@role == :user} class="h-4 w-4 text-blue-500" />
      <%= @role %>
    </div>
    """
  end

  slot :tab, required: true do
    attr :label, :string, required: true
    attr :id, :string, required: true
  end

  attr :active_tab, :string, required: true

  def tabs(assigns) do
    ~H"""
    <.page_content>
      <div class="flex items-center gap-4">
        <.link
          :for={{tab, _i} <- Enum.with_index(@tab)}
          patch={"/settings?tab=#{tab[:id]}"}
          class={[
            "px-3 py-2 text-sm rounded-lg",
            @active_tab == tab[:id] && "bg-slate-100 font-semibold"
          ]}
        >
          <%= tab[:label] %>
        </.link>
      </div>
      <div :for={tab <- @tab} class={["flex-1", (@active_tab == tab[:id] && "flex") || "hidden"]}>
        <%= render_slot(tab) %>
      </div>
    </.page_content>
    """
  end
end

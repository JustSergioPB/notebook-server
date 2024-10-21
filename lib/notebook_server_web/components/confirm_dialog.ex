defmodule NotebookServerWeb.Components.ConfirmDialog do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.info_banner content={@subtitle} variant="danger" />
      <.simple_form for={@form} id="confirm-form" phx-change="validate" phx-submit="save">
        <.input
          field={@form[:input]}
          type="text"
          label={gettext("confirm")}
          placeholder={gettext("confirm")}
          phx-debounce="blur"
          required
        />
        <:actions>
          <.button
            variant="danger"
            icon="alert-triangle"
            disabled={!User.can_use_platform?(@current_user)}
          >
            <%= gettext("confirm") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns) |> assign(:form, to_form(%{"input" => ""}))}
  end

  @impl true
  def handle_event("validate", %{"input" => input}, socket) do
    errors = if input != gettext("confirm"), do: [input: gettext("must_confirm")], else: []
    assign(socket, form: to_form(%{"input" => input}, error: errors, action: :validate))
  end

  def handle_event("save", _params, socket) do
    notify_parent({:confirmation, socket.assign.id})
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

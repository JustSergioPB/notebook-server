defmodule NotebookServerWeb.Components.ConfirmDialog do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.info_banner content={@subtitle} variant="danger" />
      <.simple_form
        for={@form}
        id="confirm-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:value]}
          type="text"
          label={gettext("confirm")}
          placeholder={gettext("confirm")}
          phx-debounce="blur"
          required
        />
        <:actions>
          <.button variant="danger" icon="alert-triangle">
            <%= gettext("confirm") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    changeset = change_confirmation(%{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(changeset, as: "confirmation") end)}
  end

  @impl true
  def handle_event("validate", %{"confirmation" => confirmation_params}, socket) do
    changeset = change_confirmation(%{}, confirmation_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "confirmation"))}
  end

  def handle_event("save", %{"confirmation" => confirmation_params}, socket) do
    changeset = change_confirmation(%{}, confirmation_params)

    if changeset.valid?,
      do: {:noreply, notify_parent({:confirmed, socket.assign.id})},
      else:
        {:noreply,
         assign(socket, form: to_form(changeset, action: :validate, as: "confirmation"))}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp change_confirmation(confirmation, attrs \\ %{}) do
    types = %{value: :string}

    {confirmation, types}
    |> Ecto.Changeset.cast(attrs, [:value])
    |> Ecto.Changeset.validate_required([:value], message: gettext("field_required"))
    |> Ecto.Changeset.validate_inclusion(:value, [gettext("confirm")],
      message: gettext("must_confirm")
    )
  end
end

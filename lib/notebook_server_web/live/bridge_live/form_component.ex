defmodule NotebookServerWeb.BridgeLive.FormComponent do
  alias NotebookServer.Bridges
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <.header class="space-y-6">
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="evidence-bridge-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="flex-1"
      >
        <div class="border border-slate-300 p-4 rounded-md shadow-sm space-y-2">
          <div class="flex items-center justify-between">
            <h3 class="font-semibold text-base">
              <%= dgettext("bridges", "email_title") %>
            </h3>
          </div>
          <p class="text-sm text-slate-600">
            <%= dgettext("bridges", "email_description") %>
          </p>
        </div>
        <:actions>
          <.button>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{bridge: bridge} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bridges.change_bridge(bridge))
     end)}
  end

  @impl true

  def handle_event("validate", %{"bridge" => bridge_params}, socket) do
    bridge_params =
      bridge_params |> Map.put("org_id", socket.assigns.current_user.org_id)

    changeset =
      Bridges.change_bridge(socket.assigns.bridge, bridge_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"bridge" => bridge_params}, socket) do
    bridge_params =
      bridge_params |> Map.put("org_id", socket.assigns.current_user.org_id)

    save_bridge(socket, socket.assigns.action, bridge_params)
  end

  defp save_bridge(socket, :edit, bridge_params) do
    case Bridges.update_bridge(socket.assigns.bridge, bridge_params) do
      {:ok, bridge} ->
        notify_parent({:saved, bridge})

        {:noreply,
         socket
         |> put_flash(:info, gettext("bridge_update_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bridge(socket, :new, bridge_params) do
    case Bridges.create_bridge(bridge_params) do
      {:ok, bridge} ->
        notify_parent({:saved, bridge})

        {:noreply,
         socket
         |> put_flash(:info, gettext("bridge_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

defmodule NotebookServerWeb.OrgLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Orgs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage org records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="org-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Org</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{org: org} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Orgs.change_org(org))
     end)}
  end

  @impl true
  def handle_event("validate", %{"org" => org_params}, socket) do
    changeset = Orgs.change_org(socket.assigns.org, org_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"org" => org_params}, socket) do
    save_org(socket, socket.assigns.action, org_params)
  end

  defp save_org(socket, :edit, org_params) do
    case Orgs.update_org(socket.assigns.org, org_params) do
      {:ok, org} ->
        notify_parent({:saved, org})

        {:noreply,
         socket
         |> put_flash(:info, "Org updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_org(socket, :new, org_params) do
    case Orgs.create_org(org_params) do
      {:ok, org} ->
        notify_parent({:saved, org})

        {:noreply,
         socket
         |> put_flash(:info, "Org created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

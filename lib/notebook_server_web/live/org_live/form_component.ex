defmodule NotebookServerWeb.OrgLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Orgs
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="org-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label={gettext("name")} />
        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}><%= gettext("save") %></.button>
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
    if User.can_use_platform?(socket.assigns.current_user) do
      save_org(socket, socket.assigns.action, org_params)
    else
      {:noreply, socket}
    end
  end

  defp save_org(socket, :edit, org_params) do
    case Orgs.update_org(socket.assigns.org, org_params) do
      {:ok, org} ->
        notify_parent({:saved, org})

        {:noreply,
         socket
         |> put_flash(:info, gettext("org_update_success"))
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
         |> put_flash(:info, gettext("org_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

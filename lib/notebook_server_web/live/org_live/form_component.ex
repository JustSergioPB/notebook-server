defmodule NotebookServerWeb.OrgLive.FormComponent do
  alias NotebookServer.Orgs
  use NotebookServerWeb, :live_component
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
        <.input
          field={@form[:name]}
          type="text"
          label={dgettext("orgs", "name")}
          placeholder={dgettext("orgs", "name_placeholder")}
          phx-debounce="blur"
        />
        <.input
          field={@form[:email]}
          type="email"
          label={dgettext("orgs", "email")}
          placeholder={dgettext("orgs", "email_placeholder")}
          phx-debounce="blur"
        />
        <:actions>
          <.button><%= dgettext("orgs", "save") %></.button>
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
         |> put_flash(:info, dgettext("orgs", "org_update_succeded"))
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
         |> put_flash(:info, dgettext("orgs", "org_creation_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

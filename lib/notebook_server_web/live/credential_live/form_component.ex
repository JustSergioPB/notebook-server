defmodule NotebookServerWeb.CredentialLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.Credentials
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
      </.header>

      <.simple_form
        for={@form}
        id="credential-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >

        <:actions>
          <.button disabled={!User.can_use_platform?(@current_user)}>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{credential: credential} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Credentials.change_credential(credential))
     end)}
  end

  @impl true
  def handle_event("validate", %{"credential" => credential_params}, socket) do
    changeset = Credentials.change_credential(socket.assigns.credential, credential_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"credential" => credential_params}, socket) do
    save_credential(socket, socket.assigns.action, credential_params)
  end

  defp save_credential(socket, :edit, credential_params) do
    case Credentials.update_credential(socket.assigns.credential, credential_params) do
      {:ok, credential} ->
        notify_parent({:saved, credential})

        {:noreply,
         socket
         |> put_flash(:info, gettext("credential_updated_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_credential(socket, :new, credential_params) do
    case Credentials.create_credential(credential_params) do
      {:ok, credential} ->
        notify_parent({:saved, credential})

        {:noreply,
         socket
         |> put_flash(:info, gettext("credential_created_successfully"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

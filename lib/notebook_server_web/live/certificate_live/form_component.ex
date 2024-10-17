defmodule NotebookServerWeb.CertificateLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.PKIs
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
        id="certificate-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          type="text"
          field={@form[:field]}
          label={if @tab == "user_certificates", do: gettext("user"), else: gettext("org")}
          placeholder={
            if @tab == "user_certificates",
              do: gettext("email_placeholder"),
              else: gettext("org_name_placeholder")
          }
        />
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
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(%{field: ""})
     end)}
  end

  @impl true
  def handle_event("save", %{"certificate" => certificate_params}, socket) do
    save_certificate(socket, socket.assigns.action, certificate_params)
  end

  defp save_certificate(socket, :new, _certificate_params) do
    notify_parent({:saved, %{field: ""}})
    {:noreply, socket}
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

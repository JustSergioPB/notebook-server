defmodule NotebookServerWeb.CertificateLive.RevokeFormComponent do
  alias NotebookServer.Certificates
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.info_banner content={@subtitle} variant="danger" />
      <.simple_form
        for={@form}
        id="revocation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.inputs_for :let={certificate_form} field={@form[:certificate]}>
          <.input
            field={certificate_form[:revocation_reason]}
            type="textarea"
            rows={2}
            label={dgettext("certificates", "revocation_reason")}
            placeholder={dgettext("certificates", "revocation_reason_placeholder")}
            phx-debounce="blur"
            required
          />
        </.inputs_for>
        <:actions>
          <.button variant="danger" icon="alert-triangle">
            <%= gettext("revoke") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{certificate: certificate, tab: tab} = assigns, socket) do
    atom = tab |> String.to_atom()
    changeset = Certificates.change_certificate(atom, certificate)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(changeset) end)}
  end

  @impl true
  def handle_event("validate", params, socket) do
    atom = socket.assigns.tab |> String.to_atom()

    changeset =
      Certificates.change_certificate(
        atom,
        socket.assigns.certificate,
        params["#{socket.assigns.tab}_certificate"]
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", params, socket) do
    atom = socket.assigns.tab |> String.to_atom()

    case Certificates.revoke_certificate(
           atom,
           Certificates.change_certificate(atom, socket.assigns.certificate),
           params["#{socket.assigns.tab}_certificate"]
         ) do
      {:ok, certificate, message} ->
        notify_parent({:revoked, atom, certificate})
        {:noreply, socket |> put_flash(:info, message) |> push_patch(to: socket.assigns.patch)}

      {:error, changeset, message} ->
        {:noreply, socket |> put_flash(:error, message) |> assign(:form, to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

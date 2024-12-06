defmodule NotebookServerWeb.CertificateLive.RevokeFormComponent do
  alias NotebookServer.Certificates
  alias NotebookServer.Certificates.Certificate
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <.header class="p-6">
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="revocation-form"
        variant="app"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.info_banner content={@subtitle} variant="danger" />
        <.input
          field={@form[:revocation_reason]}
          type="textarea"
          rows={2}
          label={dgettext("certificates", "revocation_reason")}
          placeholder={dgettext("certificates", "revocation_reason_placeholder")}
          phx-debounce="blur"
          required
        />
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
  def update(%{certificate: certificate} = assigns, socket) do
    changeset = change_certificate(certificate.certificate)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn -> to_form(changeset, as: "certificate") end)}
  end

  @impl true
  def handle_event("validate", %{"certificate" => certificate_params}, socket) do
    changeset =
      Certificates.change_certificate(
        socket.assigns.certificate.certificate,
        certificate_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "certificate"))}
  end

  def handle_event("save", %{"certificate" => certificate_params}, socket) do
    atom = socket.assigns.tab |> String.to_atom()
    certificate_params = Map.put(certificate_params, "revocation_date", DateTime.utc_now())

    case Certificates.revoke_certificate(
           atom,
           socket.assigns.certificate,
           certificate_params
         ) do
      {:ok, certificate} ->
        notify_parent({:revoked, atom, certificate})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("certificates", "revokation_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, :revoke_related_certificates, _, _} ->
        {:noreply,
         put_flash(socket, :error, dgettext("certificates", "related_revokation_failed"))}

      {:error, :revoke_certificate, _, _} ->
        {:noreply, put_flash(socket, :error, dgettext("certificates", "revokation_failed"))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, dgettext("certificates", "revokation_failed"))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp change_certificate(%Certificate{} = certificate, attrs \\ %{}) do
    types = %{revocation_reason: :string}

    {certificate, types}
    |> Ecto.Changeset.cast(attrs, [:revocation_reason])
    |> Ecto.Changeset.validate_required([:revocation_reason], message: gettext("field_required"))
    |> Ecto.Changeset.validate_length(:revocation_reason, min: 2, max: 255)
  end
end

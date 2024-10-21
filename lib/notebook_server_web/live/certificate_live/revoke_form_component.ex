defmodule NotebookServerWeb.CertificateLive.RevokeFormComponent do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  alias NotebookServer.Accounts.User
  alias NotebookServer.PKIs

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
        <.input
          field={@form[:revocation_reason]}
          type="textarea"
          rows={2}
          label={gettext("revocation_reason")}
          placeholder={gettext("revocation_reason_placeholder")}
          phx-debounce="blur"
          required
        />
        <:actions>
          <.button
            variant="danger"
            icon="alert-triangle"
            disabled={!User.can_use_platform?(@current_user)}
          >
            <%= gettext("revoke") %>
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
     |> assign_new(:form, fn -> to_form(%{"revocation_reason" => ""}) end)}
  end

  @impl true
  def handle_event("validate", %{"revocation_reason" => revocation_reason}, socket) do
    errors =
      if String.length(revocation_reason) < 2 || String.length(revocation_reason) > 255,
        do: [revocation_reason: {"revocation_reason_length %{min} %{max}", [min: 2, max: 255]}],
        else: []

    {:noreply,
     socket
     |> assign(
       form:
         to_form(%{"revocation_reason" => revocation_reason}, errors: errors, action: :validate)
     )}
  end

  def handle_event("save", %{"revocation_reason" => revocation_reason}, socket) do
    case socket.assigns.tab do
      "root_certificates" -> revoke_root_certificate(revocation_reason, socket)
      "org_certificates" -> revoke_org_certificate(revocation_reason, socket)
      "user_certificates" -> revoke_user_certificate(revocation_reason, socket)
    end
  end

  defp revoke_root_certificate(revocation_reason, socket) do
    case PKIs.revoke_org_certificate(socket.assigns.certificate, %{
           :revocation_reason => revocation_reason
         }) do
      {:ok, certificate} ->
        notify_parent({:revoked_root, certificate})

        {:noreply,
         socket
         |> put_flash(:info, gettext("root_certificate_revoke_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, assign(socket, form: to_form(%{"revocation_reason" => revocation_reason}))}
    end
  end

  defp revoke_org_certificate(revocation_reason, socket) do
    case PKIs.revoke_org_certificate(socket.assigns.certificate, %{
           :revocation_reason => revocation_reason
         }) do
      {:ok, certificate} ->
        notify_parent({:revoked_intermediate, certificate})

        {:noreply,
         socket
         |> put_flash(:info, gettext("org_certificate_revoke_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, assign(socket, form: to_form(%{"revocation_reason" => revocation_reason}))}
    end
  end

  defp revoke_user_certificate(revocation_reason, socket) do
    case PKIs.revoke_user_certificate(socket.assigns.certificate, %{
           :revocation_reason => revocation_reason
         }) do
      {:ok, certificate} ->
        notify_parent({:revoked_user, certificate})

        {:noreply,
         socket
         |> put_flash(:info, gettext("user_certificate_revoke_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, assign(socket, form: to_form(%{"revocation_reason" => revocation_reason}))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

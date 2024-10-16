defmodule NotebookServerWeb.CertificateLive.Index do
  use NotebookServerWeb, :live_view

  alias NotebookServer.PKIs
  alias NotebookServer.PKIs.UserCertificate
  alias NotebookServer.Accounts.User
  alias NotebookServer.Accounts
  alias NotebookServer.Orgs
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)
    {:ok, stream(socket, :certificates, PKIs.list_user_certificates(opts))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_certificate"))
    |> assign(:certificate, %UserCertificate{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("certificates"))
    |> assign(:certificate, nil)
  end

  @impl true
  def handle_info({NotebookServerWeb.CertificateLive.FormComponent, {:saved, certificate}}, socket) do
    # TODO: check if there's a better way to do this
    org = Orgs.get_org!(certificate.org_id)
    user = Accounts.get_user!(certificate.user_id)
    certificate = Map.put(certificate, :org, org)
    certificate = Map.put(certificate, :user, user)
    {:noreply, stream_insert(socket, :certificates, certificate)}
  end

  @impl true
  def handle_event("rotate_certificate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      # TODO: Add logic to check wether the user has a certificate pair or not
      user = Accounts.get_user!(id)
      user_certificate = PKIs.get_user_certificate_by_user_id(user.id)

      PKIs.rotate_certificate(user.id, user.org_id, user_certificate)
      |> case do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(:info, gettext("certificate_rotated"))
            |> stream(:certificates, PKIs.list_user_certificates(org_filter(socket)))

          {:noreply, socket}

        {:error} ->
          {:noreply, put_flash(socket, :error, gettext("error_rotating_certificate"))}
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("revoke_certificate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      # TODO: Add logic to check wether the user has a certificate pair or not
      user = Accounts.get_user!(id)
      user_certificate = PKIs.get_user_certificate_by_user_id(user.id)

      PKIs.revoke_certificate(user_certificate)
      |> case do
        {:ok, _} ->
          socket =
            socket
            |> put_flash(:info, gettext("certificate_revoked"))
            |> stream(:certificates, PKIs.list_user_certificates(org_filter(socket)))

          {:noreply, socket}

        {:error} ->
          {:noreply, put_flash(socket, :error, gettext("error_revoking_certificate"))}
      end
    else
      {:noreply, socket}
    end
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

defmodule NotebookServerWeb.CertificateLive.Index do
  use NotebookServerWeb, :live_view_app

  alias NotebookServer.PKIs
  alias NotebookServer.Accounts.User
  alias NotebookServer.Accounts
  alias NotebookServer.Orgs
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    opts = org_filter(socket)

    socket =
      socket
      |> stream(:user_certificates, PKIs.list_user_certificates(opts))
      |> stream(:org_certificates, PKIs.list_org_certificates(opts))

    socket =
      if socket.assigns.current_user.role == :admin do
        socket |> stream(:root_certificates, PKIs.list_org_certificates(opts ++ [level: :root]))
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:active_tab, params["tab"] || "user_certificates")}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, gettext("new_certificate"))
    |> assign(:certificate, %{})
  end

  defp apply_action(socket, :revoke, %{"id" => id, "tab" => tab}) do
    certificate =
      if tab == "user_certificates",
        do: PKIs.get_user_certificate!(id),
        else: PKIs.get_org_certificate!(id)

    socket
    |> assign(:page_title, gettext("revoke_certificate"))
    |> assign(:page_subtitle, gettext("revoke_certificate_subtitle"))
    |> assign(:certificate, certificate)
  end

  defp apply_action(socket, :delete, %{"id" => id, "tab" => tab}) do
    certificate =
      if tab == "user_certificates",
        do: PKIs.get_user_certificate!(id),
        else: PKIs.get_org_certificate!(id)

    socket
    |> assign(:page_title, gettext("delete_certificate"))
    |> assign(:page_subtitle, gettext("delete_certificate_subtitle"))
    |> assign(:certificate, certificate)
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("certificates"))
    |> assign(:certificate, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.CertificateLive.FormComponent, {:saved_root, certificate}},
        socket
      ) do
    org = Orgs.get_org!(certificate.org_id)
    certificate = Map.put(certificate, :org, org)
    {:noreply, stream_insert(socket, :root_certificates, certificate)}
  end

  def handle_info(
        {NotebookServerWeb.CertificateLive.FormComponent, {:saved_intermediate, certificate}},
        socket
      ) do
    org = Orgs.get_org!(certificate.org_id)
    certificate = Map.put(certificate, :org, org)
    {:noreply, stream_insert(socket, :org_certificates, certificate)}
  end

  def handle_info(
        {NotebookServerWeb.CertificateLive.FormComponent, {:saved_user, certificate}},
        socket
      ) do
    org = Orgs.get_org!(certificate.org_id)
    user = Accounts.get_user!(certificate.user_id)
    certificate = Map.put(certificate, :org, org)
    certificate = Map.put(certificate, :user, user)
    {:noreply, stream_insert(socket, :user_certificates, certificate)}
  end

  def handle_info(
        {NotebookServerWeb.CertificateLive.RevokeFormComponent, {:revoked_root, _certificate}},
        socket
      ) do
    opts = org_filter(socket)

    {:noreply,
     socket |> stream(:root_certificates, PKIs.list_org_certificates(opts ++ [level: :root]))}
  end

  def handle_info(
        {NotebookServerWeb.CertificateLive.RevokeFormComponent,
         {:revoked_intermediate, _certificate}},
        socket
      ) do
    opts = org_filter(socket)

    {:noreply,
     socket |> stream(:org_certificates, PKIs.list_org_certificates(opts ++ [level: :root]))}
  end

  def handle_info(
        {NotebookServerWeb.CertificateLive.RevokeFormComponent, {:revoked_user, _certificate}},
        socket
      ) do
    opts = org_filter(socket)

    {:noreply,
     socket |> stream(:user_certificates, PKIs.list_org_certificates(opts ++ [level: :root]))}
  end

  @impl true
  def handle_event("rotate_root_certificate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      opts = org_filter(socket)
      certificate = PKIs.get_org_certificate!(id)
      {:ok, _} = PKIs.rotate_org_certificate(certificate)

      {:noreply,
       socket |> stream(:root_certificates, PKIs.list_org_certificates(opts ++ [level: :root]))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("rotate_org_certificate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      opts = org_filter(socket)
      certificate = PKIs.get_org_certificate!(id)
      {:ok, _} = PKIs.rotate_org_certificate(certificate)

      {:noreply, socket |> stream(:org_certificates, PKIs.list_org_certificates(opts))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("rotate_user_certificate", %{"id" => id}, socket) do
    if User.can_use_platform?(socket.assigns.current_user) do
      opts = org_filter(socket)
      certificate = PKIs.get_user_certificate!(id)
      {:ok, _} = PKIs.rotate_user_certicate(certificate)

      {:noreply, socket |> stream(:user_certificates, PKIs.list_user_certificates(opts))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("delete", %{"id" => _id}, socket) do
    {:noreply, socket}
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

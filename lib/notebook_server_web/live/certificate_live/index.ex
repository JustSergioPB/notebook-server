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

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, gettext("certificates"))
    |> assign(:certificate, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.CertificateLive.FormComponent, {:saved, certificate}},
        socket
      ) do
    # TODO: check if there's a better way to do this
    org = Orgs.get_org!(certificate.org_id)
    user = Accounts.get_user!(certificate.user_id)
    certificate = Map.put(certificate, :org, org)
    certificate = Map.put(certificate, :user, user)
    {:noreply, stream_insert(socket, :certificates, certificate)}
  end

  @impl true
  def handle_event("rotate_certificate", %{"id" => _id}, socket) do
    {:noreply, socket}
  end

  def handle_event("revoke_certificate", %{"id" => _id}, socket) do
    {:noreply, socket}
  end

  defp org_filter(socket) do
    if socket.assigns.current_user.role == :admin,
      do: [],
      else: [org_id: socket.assigns.current_user.org_id]
  end
end

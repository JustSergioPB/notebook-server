defmodule NotebookServerWeb.CertificateLive.Index do
  alias NotebookServer.Certificates.OrgCertificate
  alias NotebookServer.Certificates.UserCertificate
  alias NotebookServer.Certificates
  alias NotebookServer.Accounts
  alias NotebookServer.Orgs
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:user_certificates, Certificates.list_certificates(:user))
      |> stream(:org_certificates, Certificates.list_certificates(:org))

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> apply_action(socket.assigns.live_action, params)
     |> assign(:active_tab, params["tab"] || "user")}
  end

  defp apply_action(socket, :new, %{"tab" => tab}) do
    certificate = if tab == "user", do: %UserCertificate{}, else: %OrgCertificate{}

    socket
    |> assign(:page_title, dgettext("certificates", "new"))
    |> assign(:certificate, certificate)
  end

  defp apply_action(socket, :revoke, %{"id" => id, "tab" => tab}) do
    atom = tab |> String.to_atom()
    certificate = Certificates.get_certificate!(atom, id)

    socket
    |> assign(:page_title, dgettext("certificates", "revoke"))
    |> assign(:page_subtitle, dgettext("certificates", "revoke_subtitle"))
    |> assign(:certificate, certificate)
  end

  defp apply_action(socket, :delete, %{"id" => id, "tab" => tab}) do
    socket
    |> assign(:page_title, dgettext("certificates", "delete"))
    |> assign(:page_subtitle, dgettext("certificates", "delete_subtitle"))
    |> assign(:certificate, %{id: id, term: tab})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, dgettext("certificates", "title"))
    |> assign(:certificate, nil)
  end

  @impl true
  def handle_info(
        {NotebookServerWeb.CertificateLive.FormComponent, {:saved, term, certificate}},
        socket
      ) do
    {:noreply, socket |> update_row(term, certificate)}
  end

  def handle_info(
        {NotebookServerWeb.CertificateLive.RevokeFormComponent, {:revoked, term, certificate}},
        socket
      ) do
    {:noreply, socket |> update_row(term, certificate)}
  end

  def handle_info(
        {NotebookServerWeb.Components.ConfirmDialog, {:confirmed, id, term}},
        socket
      ) do
    atom = term |> String.to_atom()
    certificate = Certificates.get_certificate!(atom, id)

    case Certificates.delete_certificate(atom, certificate) do
      {:ok, message} ->
        {:noreply, socket |> put_flash(:info, message) |> delete_row(atom, certificate)}

      {:error, message} ->
        {:noreply, socket |> put_flash(:error, message)}
    end
  end

  @impl true
  def handle_event("rotate", %{"id" => id, "term" => term}, socket) do
    atom = term |> String.to_atom()
    certificate = Certificates.get_certificate!(atom, id)
    changeset = Certificates.change_certificate(atom, certificate)

    case Certificates.rotate_certificate(atom, changeset) do
      {:ok, certificate, replacement, message} ->
        {:noreply,
         socket
         |> put_flash(:info, message)
         |> update_row(atom, certificate)
         |> update_row(atom, replacement)}

      {:error, message} ->
        {:noreply, socket |> put_flash(:error, message)}
    end
  end

  defp delete_row(socket, :user, user_certificate) do
    socket |> stream_delete(:user_certificates, user_certificate)
  end

  defp delete_row(socket, :org, org_certificate) do
    socket |> stream_delete(:org_certificates, org_certificate)
  end

  defp update_row(socket, :user, user_certificate) do
    org = Orgs.get_org!(user_certificate.org_id)
    user = Accounts.get_user!(user_certificate.user_id)
    user_certificate = user_certificate |> Map.merge(%{user: user, org: org})
    socket |> stream_insert(:user_certificates, user_certificate)
  end

  defp update_row(socket, :org, org_certificate) do
    org = Orgs.get_org!(org_certificate.org_id)
    org_certificate = org_certificate |> Map.put(:org, org)
    socket |> stream_insert(:org_certificates, org_certificate)
  end
end

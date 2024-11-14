defmodule NotebookServerWeb.DashboardLive.Show do
  use NotebookServerWeb, :live_view_app
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <.page_header icon="layout-dashboard">
      <%= gettext("dashboard_title") %>
    </.page_header>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

defmodule NotebookServerWeb.DashboardLive do
  use NotebookServerWeb, :live_view
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <.page_header icon="layout-dashboard">
      <%= gettext("home_title") %>
    </.page_header>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

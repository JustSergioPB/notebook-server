defmodule NotebookServerWeb.DashboardLive do
  use NotebookServerWeb, :live_view
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <.page_header icon="layout-dashboard">
      <h1><%= gettext("home_title") %></h1>
    </.page_header>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end

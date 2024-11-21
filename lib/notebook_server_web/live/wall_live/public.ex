defmodule NotebookServerWeb.WallLive.Public do
  alias NotebookServer.Bridges.EvidenceBridge
  alias NotebookServer.Bridges
  alias NotebookServer.Orgs
  use NotebookServerWeb, :live_view_blank
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <main class="h-screen py-12">
      <.header class="mb-12 px-64">
        <%= gettext("wall_title %{org_name}", org_name: @org.name) %>
        <:subtitle>
          <%= gettext("wall_subtitle") %>
        </:subtitle>
      </.header>
      <.tabs class="h-full" active_tab={@active_tab} variant="public">
        <:tab label={gettext("bridges")} id="bridges" patch={~p"/wall/show?tab=bridges"}>
          <h2 class="text-2xl font-semibold"><%= gettext("bridges") %></h2>
          <p class="text-slate-600 mb-6"><%= gettext("obtain_bridge_credentials") %></p>
          <%= if Enum.count(@streams.evidence_bridges) > 0 do %>
            <div class="grid grid-cols-4 gap-6">
              <div
                :for={{_, evidence_bridge} <- @streams.evidence_bridges}
                class="border border-slate-300 p-4 rounded-lg space-y-6 h-48 mx-h-48 flex flex-col"
              >
                <div class="space-y-2 flex-1">
                  <h3 class="font-semibold"><%= evidence_bridge.published_version.title %></h3>
                  <p class="text-sm text-slate-600">
                    <%= evidence_bridge.published_version.description %>
                  </p>
                </div>
                <.link navigate={
                  ~p"/#{@org.public_id}/wall/evidence-bridges/email/#{evidence_bridge.public_id}"
                }>
                  <.button icon="arrow-right" icon_side="right" class="w-full">
                    <%= gettext("get") %>
                  </.button>
                </.link>
              </div>
            </div>
          <% else %>
            <div class="flex items-center justify-center h-full">
              <div class="flex flex-col items-center">
                <h3 class="text-lg font-semibold mb-1">
                  <%= dgettext("evidence_bridges", "empty_public_title") %>
                </h3>
                <p class="font-sm text-slate-600 mb-6">
                  <%= dgettext("evidence_bridges", "empty_public_subtitle") %>
                </p>
                <Lucide.unplug class="h-10 w-10 text-slate-600" />
              </div>
            </div>
          <% end %>
        </:tab>
      </.tabs>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_params(%{"id" => id} = params, _url, socket) do
    org = Orgs.get_org_by_public_id!(id)

    {:noreply,
     socket
     |> assign(:page_title, gettext("public_wall_bridges"))
     |> assign(:active_tab, params["tab"] || "bridges")
     |> assign(:org, org)
     |> stream(
       :evidence_bridges,
       Bridges.list_evidence_bridges(org_id: org.id, active: true)
       |> Enum.map(fn evidence_bridge -> evidence_bridge |> EvidenceBridge.map_to_wall() end)
     )}
  end
end

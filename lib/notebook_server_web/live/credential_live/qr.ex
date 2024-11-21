defmodule NotebookServerWeb.CredentialLive.Qr do
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>

      <div class="flex items-center justify-center">
        <img
          src={"/qrs/#{@credential.credential.public_id}-qr.svg"}
          width="400"
          height="400"
          alt={gettext("qr_alt")}
        />
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok, socket |> assign(assigns)}
  end
end

defmodule NotebookServerWeb.CertificateLive.FormComponent do
  use NotebookServerWeb, :live_component

  alias NotebookServer.PKIs
  alias NotebookServer.Accounts.User
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.header>
        <%= @title %>
      </.header>
      <.simple_form for={@form} id="certificate-form" phx-target={@myself} phx-submit="save">
        <.input
          type={if @tab == "user_certificates", do: "email", else: "text"}
          field={@form[:field]}
          label={if @tab == "user_certificates", do: gettext("user"), else: gettext("org")}
          placeholder={
            if @tab == "user_certificates",
              do: gettext("email_placeholder"),
              else: gettext("org_name_placeholder")
          }
          required
        />
        <:actions>
          <.button disabled={disable_button?(@current_user, @tab)}>
            <%= gettext("save") %>
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
     |> assign_new(:form, fn ->
       to_form(%{"field" => ""})
     end)}
  end

  @impl true
  def handle_event("save", %{"field" => field}, socket) do
    case socket.assigns.tab do
      "root_certificates" -> create_root_ca(socket)
      "org_certificates" -> create_org_certificate(field, socket)
      "user_certificates" -> create_user_certificate(field, socket)
    end
  end

  defp create_root_ca(socket) do
    case PKIs.create_root_certificate() do
      {:ok, certificate} ->
        notify_parent({:saved_root, certificate})

        {:noreply,
         socket
         |> put_flash(:info, gettext("root_certificate_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, gettext("root_certificate_create_error"))}
    end
  end

  defp create_org_certificate(field, socket) do
    case PKIs.create_org_certificate(field) do
      {:ok, certificate} ->
        notify_parent({:saved_intermediate, certificate})

        {:noreply,
         socket
         |> put_flash(:info, gettext("org_certificate_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, gettext("org_certificate_create_error"))}
    end
  end

  defp create_user_certificate(field, socket) do
    case PKIs.create_user_certificate(field) do
      {:ok, certificate} ->
        notify_parent({:saved_user, certificate})

        {:noreply,
         socket
         |> put_flash(:info, gettext("user_certificate_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, gettext("user_certificate_create_error"))}
    end
  end

  defp disable_button?(user, tab) do
    !User.can_use_platform?(user) || (tab == "root_certificates" && user.role != :admin)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

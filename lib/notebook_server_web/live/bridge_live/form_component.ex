defmodule NotebookServerWeb.BridgeLive.FormComponent do
  alias NotebookServer.Bridges
  use NotebookServerWeb, :live_component
  use Gettext, backend: NotebookServerWeb.Gettext

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col">
      <.header>
        <%= @title %>
      </.header>
      <.simple_form
        for={@form}
        id="evidence-bridge-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.inputs_for :let={schema_form} field={@form[:schema]}>
          <.input
            type="text"
            field={schema_form[:title]}
            label={dgettext("bridges", "title")}
            placeholder={dgettext("bridges", "title_placeholder")}
            hint={gettext("max_chars %{max}", max: 50)}
            phx-debounce="blur"
            required
          />
          <.inputs_for :let={schema_version_form} field={schema_form[:schema_versions]}>
            <.input
              type="textarea"
              rows="2"
              field={schema_version_form[:description]}
              label={dgettext("bridges", "description")}
              placeholder={dgettext("bridges", "description_placeholder")}
              hint={gettext("max_chars %{max}", max: 255)}
              phx-debounce="blur"
            />
            <.input
              type="radio"
              label={dgettext("schemas", "platform")}
              field={schema_version_form[:platform]}
              disabled={true}
              options={[
                %{
                  id: :web2,
                  icon: "globe",
                  label: dgettext("bridges", "web_2_title"),
                  description: dgettext("bridges", "web_2_description")
                },
                %{
                  id: :web3,
                  icon: "link",
                  label: dgettext("bridges", "web_3_title"),
                  description: dgettext("bridges", "web_3_description")
                }
              ]}
            />
            <.input
              type="radio"
              label={dgettext("bridges", "type")}
              disabled={true}
              field={@form[:type]}
              options={[
                %{
                  id: :email,
                  icon: "mail",
                  label: dgettext("bridges", "email_title"),
                  description: dgettext("bridges", "email_description")
                }
              ]}
            />
            <.inputs_for :let={schema_content_form} field={schema_version_form[:content]}>
              <.inputs_for :let={properties_form} field={schema_content_form[:properties]}>
                <.inputs_for
                  :let={credential_subject_form}
                  field={properties_form[:credential_subject]}
                >
                  <.inputs_for :let={props_form} field={credential_subject_form[:properties]}>
                    <.input
                      type="chip"
                      field={props_form[:content]}
                      label={dgettext("bridges", "domains")}
                      placeholder={dgettext("bridges", "domains_placeholder")}
                      hint={dgettext("bridges", "domains_hint")}
                      autocomplete="off"
                      rows="3"
                      phx-debounce="blur"
                      required
                    />
                  </.inputs_for>
                </.inputs_for>
              </.inputs_for>
            </.inputs_for>
          </.inputs_for>
        </.inputs_for>
        <:actions>
          <.button>
            <%= gettext("save") %>
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{bridge: bridge} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Bridges.change_bridge(bridge))
     end)}
  end

  @impl true

  def handle_event("validate", %{"bridge" => bridge_params}, socket) do
    bridge_params =
      bridge_params |> Map.put("org_id", socket.assigns.current_user.org_id)

    changeset =
      Bridges.change_bridge(socket.assigns.bridge, bridge_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"bridge" => bridge_params}, socket) do
    bridge_params =
      bridge_params |> Map.put("org_id", socket.assigns.current_user.org_id)

    save_bridge(socket, socket.assigns.action, bridge_params)
  end

  defp save_bridge(socket, :edit, bridge_params) do
    case Bridges.update_bridge(socket.assigns.bridge, bridge_params) do
      {:ok, bridge} ->
        notify_parent({:saved, bridge})

        {:noreply,
         socket
         |> put_flash(:info, gettext("bridge_update_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_bridge(socket, :new, bridge_params) do
    case Bridges.create_bridge(bridge_params) do
      {:ok, bridge} ->
        notify_parent({:saved, bridge})

        {:noreply,
         socket
         |> put_flash(:info, gettext("bridge_create_success"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end

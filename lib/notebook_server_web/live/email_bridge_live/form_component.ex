defmodule NotebookServerWeb.EmailBridgeLive.FormComponent do
  alias NotebookServer.Bridges
  alias NotebookServer.Orgs
  alias NotebookServer.Bridges.EmailBridge
  alias NotebookServerWeb.JsonSchemaComponents
  use NotebookServerWeb, :live_view_blank
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <main class="h-screen flex flex-col items-center justify-center">
      <div class="flex flex-col w-1/3 space-y-12">
        <.back navigate={~p"/#{@org.public_id}/wall"}><%= gettext("go_back") %></.back>
        <.stepper active_step={@step}>
          <:step label={dgettext("email_bridges", "email")} step={1}>
            <.simple_form
              id="credential-form"
              for={@email_bridge_form}
              class={if @step == 1, do: "flex w-full", else: "hidden"}
              phx-change="validate-email-bridge"
              phx-submit="submit-email-bridge"
            >
              <.header class="mb-12">
                <%= dgettext("email_bridges", "introduce_email_title") %>
                <:subtitle>
                  <%= dgettext("email_bridges", "introduce_email_description") %>
                </:subtitle>
              </.header>
              <.inputs_for
                :let={org_credential_form}
                :if={@step == 1}
                field={@email_bridge_form[:org_credential]}
              >
                <.inputs_for :let={credential_form} field={org_credential_form[:credential]}>
                  <.inputs_for :let={credential_content_form} field={credential_form[:content]}>
                    <.inputs_for
                      :let={credential_subject_form}
                      field={credential_content_form[:credential_subject]}
                    >
                      <JsonSchemaComponents.json_schema_node
                        field={credential_subject_form[:content]}
                        schema={
                          @schema_version.content.properties.credential_subject.properties.content
                        }
                      />
                    </.inputs_for>
                  </.inputs_for>
                </.inputs_for>
              </.inputs_for>
              <:actions>
                <.button>
                  <%= gettext("next") %>
                </.button>
              </:actions>
            </.simple_form>
          </:step>
          <:step label={dgettext("email_bridges", "code")} step={2}>
            <.simple_form
              id="code-form"
              class={if @step == 2, do: "flex", else: "hidden"}
              for={@code_form}
              phx-change="validate-code"
              phx-submit="submit-code-validation"
            >
              <.header class="mb-12">
                <%= dgettext("email_bridges", "introduce_code_title") %>
                <:subtitle>
                  <%= dgettext("email_bridges", "introduce_code_description") %>
                </:subtitle>
              </.header>
              <.input
                field={@code_form[:code]}
                type="text"
                label={dgettext("email_bridges", "code")}
                placeholder={dgettext("email_bridges", "code_placeholder")}
                phx-debounce="blur"
                required
              />
              <:actions>
                <.button variant="outline" type="button" phx-click="back">
                  <%= gettext("back") %>
                </.button>
                <.button>
                  <%= gettext("next") %>
                </.button>
              </:actions>
            </.simple_form>
          </:step>
          <:step label={dgettext("email_bridges", "qr")} step={3}>
            <.header class="mb-12">
              <%= dgettext("email_bridges", "scan_qr_title") %>
              <:subtitle>
                <%= dgettext("email_bridges", "scan_qr_description") %>
              </:subtitle>
            </.header>
            <img
              :if={@credential_url}
              src={@credential_url}
              width="400"
              height="400"
              alt={dgettext("email_bridges", "qr_alt")}
            />
          </:step>
        </.stepper>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, dgettext("email_bridges", "public_title"))
     |> assign(:credential_url, nil)
     |> assign(
       :email_bridge_form,
       to_form(Bridges.change_email_bridge(%EmailBridge{}))
     )
     |> assign(:code_form, to_form(%{"code" => nil}))}
  end

  def handle_params(params, _url, socket) do
    org = Orgs.get_org_by_public_id!(params["id"])
    bridge = Bridges.get_bridge_by_public_id!(params["public_id"])

    schema =
      bridge
      |> Map.get(:schema)

    schema_version =
      schema
      |> Map.get(:schema_versions)
      |> Enum.find(fn version -> version.status == :published end)
      |> Map.put(:schema, schema)

    {:noreply,
     socket
     |> assign(:step, 1)
     |> assign(:org, org)
     |> assign(:bridge, bridge)
     |> assign(:schema_version, schema_version)}
  end

  def handle_event("back", _, socket) do
    {:noreply, socket |> assign(:step, socket.assigns.step - 1)}
  end

  def handle_event(
        "validate-email-bridge",
        %{"email_bridge" => email_bridge_params},
        socket
      ) do
    email_bridge_params =
      socket |> gen_complete_email_bridge(email_bridge_params)

    changeset =
      Bridges.change_email_bridge(%EmailBridge{}, email_bridge_params)

    {:noreply, assign(socket, email_bridge_form: to_form(changeset, action: :validate))}
  end

  def handle_event("validate-code", %{"code" => code}, socket) do
    errors =
      if String.length(code) == 0,
        do: [code: gettext("field_required")],
        else: []

    errors =
      if String.length(code) > 6,
        do: [code: dgettext("email_bridges", "invalid_code_length")],
        else: errors

    errors =
      if !String.match?(code, ~r/^\d{6}$/),
        do: [code: dgettext("email_bridges", "invalid_code_format")],
        else: errors

    {:noreply,
     socket |> assign(:code_form, to_form(%{"code" => code}, error: errors, action: :validate))}
  end

  def handle_event(
        "submit-email-bridge",
        %{"email_bridge" => email_bridge_params},
        socket
      ) do
    email_bridge_params =
      socket |> gen_complete_email_bridge(email_bridge_params)

    case Bridges.create_email_bridge(email_bridge_params) do
      {:ok, email_bridge} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("email_bridges", "code_delivery_succeeded"))
         |> assign(:email_id, email_bridge |> Map.get(:id))
         |> assign(:step, socket.assigns.step + 1)}

      {:error, _, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("email_bridges", "creation_failed"))
         |> assign(:email_bridge_form, to_form(changeset, action: :validate))}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("email_bridges", "code_delivery_failed"))}
    end
  end

  def handle_event("submit-code-validation", %{"code" => code}, socket) do
    case Bridges.validate_email_bridge(%EmailBridge{
           id: socket.assigns.email_id,
           code: code
         }) do
      {:ok, email_bridge} ->
        public_id = email_bridge.org_credential.credential.public_id

        {:noreply,
         socket
         |> put_flash(:info, dgettext("email_bridges", "credential_creation_succeeded"))
         |> assign(:credential_url, "/qrs/#{public_id}-qr.svg")
         |> assign(:step, socket.assigns.step + 1)}

      {:error, _, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("email_bridges", "update_failed"))
         |> assign(:email_bridge_form, to_form(changeset, action: :validate))}

      {:error, atom} ->
        message =
          case atom do
            :find_email_bridge -> dgettext("email_bridges", "search_failed")
            :check_code -> dgettext("email_bridges", "check_failed")
          end

        {:noreply,
         socket
         |> put_flash(:error, message)}
    end
  end

  # TODO: move this so info is correctly generated
  defp gen_complete_email_bridge(socket, email_bridge_params) do
    org = socket.assigns.org
    schema_version = socket.assigns.schema_version
    bridge = socket.assigns.bridge
    domain_url = NotebookServerWeb.Endpoint.url()

    email =
      email_bridge_params
      |> get_in(["org_credential", "credential", "content", "credential_subject", "content"])

    credential_subject =
      email_bridge_params
      |> get_in(["org_credential", "credential", "content", "credential_subject"])
      |> Map.put("id", "TODO")

    content =
      email_bridge_params
      |> get_in(["org_credential", "credential", "content"])
      |> Map.merge(%{
        "title" => schema_version.schema.title,
        "description" => schema_version.description,
        "issuer" => "#{domain_url}/#{org.public_id}",
        "credential_schema" => %{
          "id" =>
            "#{domain_url}/#{schema_version.schema.public_id}/version/#{schema_version.public_id}"
        },
        "credential_subject" => credential_subject
      })

    credential =
      email_bridge_params
      |> get_in(["org_credential", "credential"])
      |> Map.merge(%{"schema_version_id" => schema_version.id, "content" => content})

    org_credential =
      email_bridge_params
      |> Map.get("org_credential")
      |> Map.merge(%{
        "org_id" => org.id,
        "credential" => credential
      })

    email_bridge_params
    |> Map.merge(%{
      "org_credential" => org_credential,
      "org_id" => org.id,
      "email" => email,
      "bridge_id" => bridge.id
    })
  end
end

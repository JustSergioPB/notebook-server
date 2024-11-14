defmodule NotebookServerWeb.EmailEvidenceBridgeLive.FormComponent do
  alias NotebookServer.Credentials.OrgCredential
  alias NotebookServer.Bridges
  alias NotebookServer.Orgs
  alias NotebookServer.Bridges.EmailEvidenceBridge
  alias NotebookServer.Schemas.SchemaVersion
  alias NotebookServerWeb.JsonSchemaComponents
  use NotebookServerWeb, :live_view_blank
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <main class="h-screen flex flex-col items-center justify-center">
      <div class="flex flex-col w-1/3 space-y-12">
        <.back navigate={~p"/#{@org.public_id}/wall"}><%= gettext("back") %></.back>
        <.stepper active_step={@step}>
          <:step label={gettext("email")} step={1}>
            <.simple_form
              id="credential-form"
              for={@email_evidence_bridge_form}
              class={if @step == 1, do: "flex w-full", else: "hidden"}
              phx-change="validate-email-evidence-bridge"
              phx-submit="submit-email-evidence-bridge"
            >
              <.header class="mb-12">
                <%= gettext("introduce_email_title") %>
                <:subtitle>
                  <%= gettext("introduce_email_description") %>
                </:subtitle>
              </.header>
              <.inputs_for
                :let={org_credential_form}
                :if={@step == 1}
                field={@email_evidence_bridge_form[:org_credential]}
              >
                <.inputs_for :let={credential_form} field={org_credential_form[:credential]}>
                  <.inputs_for :let={credential_content_form} field={credential_form[:content]}>
                    <.inputs_for
                      :let={credential_subject_form}
                      field={credential_content_form[:credential_subject]}
                    >
                      <JsonSchemaComponents.json_schema_node
                        field={credential_subject_form[:content]}
                        schema={@schema_version.credential_subject_content}
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
          <:step label={gettext("code")} step={2}>
            <.simple_form
              id="code-form"
              class={if @step == 2, do: "flex", else: "hidden"}
              for={@code_form}
              phx-change="validate-code"
              phx-submit="submit-code-validation"
            >
              <.header class="mb-12">
                <%= gettext("introduce_code_title") %>
                <:subtitle>
                  <%= gettext("introduce_code_description") %>
                </:subtitle>
              </.header>
              <.input
                field={@code_form[:code]}
                type="text"
                label={gettext("code")}
                placeholder={gettext("code_placeholder")}
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
          <:step label={gettext("qr")} step={3}>
            <.header class="mb-12">
              <%= gettext("scan_qr_title") %>
              <:subtitle>
                <%= gettext("scan_qr_description") %>
              </:subtitle>
            </.header>
            <img
              :if={@credential_url}
              src={@credential_url}
              width="400"
              height="400"
              alt={gettext("qr_alt")}
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
     |> assign(:page_title, gettext("public_wall_bridges"))
     |> assign(:credential_url, nil)
     |> assign(
       :email_evidence_bridge_form,
       to_form(Bridges.change_email_evidence_bridge(%EmailEvidenceBridge{}))
     )
     |> assign(:code_form, to_form(%{"code" => nil}))}
  end

  def handle_params(params, _url, socket) do
    org = Orgs.get_org_by_public_id!(params["id"])
    evidence_bridge = Bridges.get_evidence_bridge_by_public_id!(params["public_id"])

    schema =
      evidence_bridge
      |> Map.get(:schema)

    schema_version =
      schema
      |> Map.get(:schema_versions)
      |> Enum.find(fn version -> version.status == :published end)
      |> Map.put(:schema, schema)
      |> SchemaVersion.get_credential_subject_content()

    {:noreply,
     socket
     |> assign(:step, 1)
     |> assign(:org, org)
     |> assign(:evidence_bridge, evidence_bridge)
     |> assign(:schema_version, schema_version)}
  end

  def handle_event("back", _, socket) do
    {:noreply, socket |> assign(:step, socket.assigns.step - 1)}
  end

  def handle_event(
        "validate-email-evidence-bridge",
        %{"email_evidence_bridge" => email_evidence_bridge_params},
        socket
      ) do
    email_evidence_bridge_params =
      socket |> gen_complete_email_evidence_bridge(email_evidence_bridge_params)

    changeset =
      Bridges.change_email_evidence_bridge(%EmailEvidenceBridge{}, email_evidence_bridge_params)

    {:noreply, assign(socket, email_evidence_bridge_form: to_form(changeset, action: :validate))}
  end

  def handle_event("validate-code", %{"code" => code}, socket) do
    errors = if String.length(code) == 0, do: [code: gettext("field_required")], else: []
    errors = if String.length(code) > 6, do: [code: gettext("invalid_code_length")], else: errors

    errors =
      if !String.match?(code, ~r/^\d{6}$/),
        do: [code: gettext("invalid_code_format")],
        else: errors

    {:noreply,
     socket |> assign(:code_form, to_form(%{"code" => code}, error: errors, action: :validate))}
  end

  def handle_event(
        "submit-email-evidence-bridge",
        %{"email_evidence_bridge" => email_evidence_bridge_params},
        socket
      ) do
    email_evidence_bridge_params =
      socket |> gen_complete_email_evidence_bridge(email_evidence_bridge_params)

    case Bridges.create_email_evidence_bridge(email_evidence_bridge_params) do
      {:ok, email_bridge, message} ->
        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:email_evidence_id, email_bridge |> Map.get(:id))
         |> assign(:step, socket.assigns.step + 1)}

      {:error, message} ->
        {:noreply,
         socket
         |> put_flash(:error, message)}
    end
  end

  def handle_event("submit-code-validation", %{"code" => code}, socket) do
    case Bridges.validate_email_evidence_bridge(%EmailEvidenceBridge{
           id: socket.assigns.email_evidence_id,
           code: code
         }) do
      {:ok, _email_evidence_bridge, message} ->
        # public_id = email_evidence_bridge.org_credential.credential.public_id

        public_id = 0

        {:noreply,
         socket
         |> put_flash(:info, message)
         |> assign(:credential_url, "/qrs/#{public_id}-qr.svg")
         |> assign(:step, socket.assigns.step + 1)}

      {:error, message} ->
        {:noreply,
         socket
         |> put_flash(:error, message)}
    end
  end

  defp gen_complete_email_evidence_bridge(socket, email_evidence_bridge_params) do
    org = socket.assigns.org
    schema_version = socket.assigns.schema_version
    evidence_bridge = socket.assigns.evidence_bridge

    email =
      email_evidence_bridge_params
      |> get_in(["org_credential", "credential", "content", "credential_subject", "content"])

    org_credential =
      email_evidence_bridge_params
      |> Map.get("org_credential")
      |> OrgCredential.gen_full(org, schema_version)

    email_evidence_bridge_params
    |> Map.merge(%{
      "org_credential" => org_credential,
      "org_id" => org.id,
      "email" => email,
      "evidence_bridge_id" => evidence_bridge.id
    })
  end
end

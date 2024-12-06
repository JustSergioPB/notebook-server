defmodule NotebookServerWeb.EmailBridgeLive.FormComponent do
  alias NotebookServer.Bridges
  alias NotebookServer.Credentials
  alias NotebookServer.Orgs

  use NotebookServerWeb, :live_view_blank
  use Gettext, backend: NotebookServerWeb.Gettext

  def render(assigns) do
    ~H"""
    <main class="h-screen flex flex-col items-center justify-center py-12">
      <div class="flex flex-col space-y-12 h-full p-6 md:p-0 md:w-2/3 lg:w-1/2 xl:w-2/5">
        <.back navigate={~p"/#{@org_public_id}/wall"}><%= gettext("go_back") %></.back>
        <.stepper active_step={@step}>
          <:step label={dgettext("email_bridges", "email")} step={1}>
            <.simple_form
              id="email-form"
              for={@email_form}
              class={if @step == 1, do: "flex w-full", else: "hidden"}
              variant="blank"
              phx-change="validate"
              phx-submit="save"
            >
              <.header class="mb-12">
                <%= dgettext("email_bridges", "introduce_email_title") %>
                <:subtitle>
                  <%= dgettext("email_bridges", "introduce_email_description") %>
                </:subtitle>
              </.header>
              <.input
                field={@email_form[:email]}
                type="email"
                label={dgettext("users", "email")}
                placeholder={dgettext("users", "email_placeholder")}
                phx-debounce="blur"
              />
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
              variant="blank"
              phx-change="validate"
              phx-submit="save"
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
        </.stepper>
      </div>
    </main>
    """
  end

  def mount(_params, _session, socket) do
    email_changeset = change_email(%{})
    code_changeset = change_code(%{})

    {:ok,
     socket
     |> assign(:page_title, dgettext("email_bridges", "public_title"))
     |> assign(:email_form, to_form(email_changeset, as: "email"))
     |> assign(:code_form, to_form(code_changeset, as: "code"))}
  end

  def handle_params(params, _url, socket) do
    bridge = Bridges.get_bridge_by_public_id!(params["public_id"])

    schema_version =
      bridge.schema.schema_versions
      |> Enum.at(0)
      |> Map.put(:schema, bridge.schema)

    {:noreply,
     socket
     |> assign(:step, 1)
     |> assign(:org_public_id, params["id"])
     |> assign(:bridge, bridge)
     |> assign(:schema_version, schema_version)}
  end

  def handle_event("back", _, socket) do
    {:noreply, socket |> assign(:step, socket.assigns.step - 1)}
  end

  def handle_event("validate", %{"email" => email_params}, socket) do
    changeset = change_email(%{}, email_params)

    {:noreply,
     assign(socket, email_bridge_form: to_form(changeset, action: :validate, as: "email"))}
  end

  def handle_event("validate", %{"code" => code_params}, socket) do
    changeset = change_code(%{}, code_params)

    {:noreply,
     assign(socket, email_bridge_form: to_form(changeset, action: :validate, as: "code"))}
  end

  def handle_event("save", %{"email" => email_params}, socket) do
    email_bridge_params = complete_email_bridge(email_params, socket)

    case Bridges.create_email_bridge(email_bridge_params) do
      {:ok, %{create_email_bridge: email_bridge}} ->
        {:noreply,
         socket
         |> put_flash(:info, dgettext("email_bridges", "email_delivery_succeded"))
         |> assign(:step, 2)
         |> assign(:email_bridge_id, email_bridge.id)}

      {:error, :create_email_bridge, _, _} ->
        {:noreply, socket |> put_flash(:error, dgettext("email_bridges", "creation_failed"))}

      {:error, :deliver_mail, _, _} ->
        {:noreply,
         socket |> put_flash(:error, dgettext("email_bridges", "email_delivery_failed"))}
    end
  end

  def handle_event("save", %{"code" => code}, socket) do
    email_bridge = Bridges.get_email_bridge!(socket.assigns.email_bridge_id)
    org = Orgs.get_org_by_public_id!(socket.assigns.org_public_id)

    email_bridge_params = %{
      "org_credential" =>
        Credentials.complete_credential(
          :org,
          email_bridge.email,
          org,
          socket.assigns.schema_version
        )
    }

    code = Map.get(code, "code")

    # TODO add a validation of 2 mins
    if email_bridge.code != String.to_integer(code) do
      {:noreply, put_flash(socket, :error, dgettext("email_bridges", "code_validation_failed"))}
    else
      case Bridges.validate_email_bridge(email_bridge, email_bridge_params) do
        {:ok, _} ->
          {:noreply,
           put_flash(socket, :info, dgettext("email_bridges", "code_validation_succeded"))}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, dgettext("email_bridges", "update_failed"))}
      end
    end
  end

  defp change_email(email, attrs \\ %{}) do
    types = %{email: :string}

    {email, types}
    |> Ecto.Changeset.cast(attrs, [:email])
    |> Ecto.Changeset.validate_required([:email], message: gettext("field_required"))
    |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: gettext("user_email_invalid")
    )
  end

  defp change_code(code, attrs \\ %{}) do
    types = %{code: :string}

    {code, types}
    |> Ecto.Changeset.cast(attrs, [:code])
    |> Ecto.Changeset.validate_required([:code], message: gettext("field_required"))
    |> Ecto.Changeset.validate_format(:code, ~r/^\d{6}$/,
      message: dgettext("email_bridges", "invalid_code_format")
    )
  end

  defp complete_email_bridge(email_params, socket) do
    email = Map.get(email_params, "email")
    bridge = socket.assigns.bridge

    %{
      "email" => email,
      "code" => Enum.random(100_000..999_999),
      "bridge_id" => bridge.id
    }
  end
end

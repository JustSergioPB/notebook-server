defmodule NotebookServerWeb.BridgeLive.FormComponent do
  alias NotebookServer.Bridges
  alias NotebookServer.Bridges.Bridge
  alias NotebookServer.Accounts.User
  alias NotebookServer.Schemas
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
        <.input
          type="text"
          field={@form[:title]}
          label={dgettext("bridges", "title")}
          placeholder={dgettext("bridges", "title_placeholder")}
          hint={gettext("max_chars %{max}", max: 50)}
          phx-debounce="blur"
          required
        />
        <.input
          type="textarea"
          rows="2"
          field={@form[:description]}
          label={dgettext("bridges", "description")}
          placeholder={dgettext("bridges", "description_placeholder")}
          hint={gettext("max_chars %{max}", max: 255)}
          phx-debounce="blur"
        />
        <.input
          type="radio"
          label={dgettext("schemas", "platform")}
          field={@form[:platform]}
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
        <.live_component
          module={NotebookServerWeb.Components.ChipInput}
          id="pattern-chip-input"
          field={@form[:pattern]}
          label={dgettext("bridges", "domains")}
          placeholder={dgettext("bridges", "domains_placeholder")}
          hint={dgettext("bridges", "domains_hint")}
          required
        />
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
    changeset = bridge |> flatten_bridge() |> change_bridge()

    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(changeset, as: "bridge")
     end)}
  end

  @impl true

  def handle_event("validate", %{"bridge" => bridge_params}, socket) do
    changeset = socket.assigns.bridge |> flatten_bridge() |> change_bridge(bridge_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate, as: "bridge"))}
  end

  def handle_event("save", %{"bridge" => bridge_params}, socket) do
    bridge_params =
      bridge_params
      |> complete_bridge(
        socket.assigns.bridge,
        socket.assigns.current_user
      )

    save_bridge(socket, socket.assigns.action, bridge_params)
  end

  defp save_bridge(socket, :edit, bridge_params) do
    case Bridges.update_bridge(socket.assigns.bridge, bridge_params) do
      {:ok, %{update_bridge: bridge}} ->
        notify_parent({:saved, bridge})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("bridges", "update_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, :update_bridge, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("bridges", "update_failed"))}

      {:error, :update_schema, _, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schemas", "update_failed"))}

      {:error, :create_schema_version, _, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schema_versions", "create_failed"))}

      {:error, :update_schema_version, _, _} ->
        {:noreply,
         socket
         |> put_flash(:error, dgettext("schema_versions", "update_failed"))}
    end
  end

  defp save_bridge(socket, :new, bridge_params) do
    case Bridges.create_bridge(bridge_params) do
      {:ok, bridge} ->
        notify_parent({:saved, bridge})

        {:noreply,
         socket
         |> put_flash(:info, dgettext("bridges", "creation_succeded"))
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp extract_domains(pattern) do
    pattern
    |> extract_domain_pattern()
    |> String.replace("\\.", ".")
  end

  defp extract_domain_pattern(regex_string) do
    case Regex.run(~r/@\(\?:(.+?)\)\$/i, regex_string) do
      [_, domains] -> domains
      nil -> ""
    end
  end

  defp flatten_bridge(bridge) do
    latest_version =
      bridge.schema.schema_versions
      |> Enum.at(0)

    pattern =
      if is_nil(latest_version.content),
        do: nil,
        else:
          latest_version.content.properties.credential_subject.properties.content
          |> Map.get("pattern")
          |> extract_domains()

    description =
      if is_nil(latest_version.content), do: nil, else: latest_version.content.description

    %{
      title: bridge.schema.title,
      description: description,
      platform: latest_version.platform || :web2,
      type: bridge.type || :email,
      pattern: pattern
    }
  end

  defp change_bridge(bridge, attrs \\ %{}) do
    types = %{
      title: :string,
      description: :string,
      pattern: :string,
      type: :atom,
      platform: :atom
    }

    {bridge, types}
    |> Ecto.Changeset.cast(attrs, [:title, :description, :pattern])
    |> Ecto.Changeset.validate_required([:title, :pattern], message: gettext("field_required"))
    |> Ecto.Changeset.validate_length(:title,
      min: 2,
      max: 50,
      message: dgettext("bridges", "title_length %{max} %{min}", min: 2, max: 50)
    )
    |> Ecto.Changeset.validate_length(:description,
      min: 2,
      max: 255,
      message: dgettext("bridges", "title_length %{max} %{min}", min: 2, max: 255)
    )
    |> Ecto.Changeset.validate_length(:pattern, min: 2, message: gettext("field_required"))
  end

  defp complete_bridge(bridge_params, %Bridge{} = bridge, %User{} = user) do
    pattern = Map.pop(bridge_params, "pattern") |> elem(0) |> String.replace(".", "\\.")

    bridge_params =
      bridge_params
      |> Map.put("content", %{
        "pattern" => ~r/^[a-zA-Z0-9._%+-]+@(?:#{pattern})$/i |> Regex.source(),
        "type" => "string",
        "format" => "email",
        "title" => "Email",
        "examples" =>
          pattern
          |> String.replace("\\.", ".")
          |> String.split("|")
          |> Enum.map(fn domain -> "john.doe@#{domain}" end)
      })

    %{
      "org_id" => user.org_id,
      "schema" => Schemas.complete_schema(bridge_params, bridge.schema, user)
    }
  end
end

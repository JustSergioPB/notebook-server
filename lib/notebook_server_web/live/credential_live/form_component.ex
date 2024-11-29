defmodule NotebookServerWeb.CredentialLive.FormComponent do
  alias NotebookServer.Schemas
  alias NotebookServer.Credentials
  alias NotebookServerWeb.Components.SelectSearch
  alias NotebookServerWeb.JsonSchemaComponents
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
        phx-target={@myself}
        id="credential-form"
        phx-change="validate"
        phx-submit="save"
      >
        <.live_component
          field={@form[:schema_version_id]}
          id={@form[:schema_version_id].id}
          module={SelectSearch}
          label={gettext("search_schema")}
          options={@schema_version_options}
          placeholder={gettext("title_placeholder") <> "..."}
          autocomplete="autocomplete_schemas"
          target="#credential-form"
        >
          <:option :let={schema}>
            <.schema_version_option schema={schema} />
          </:option>
        </.live_component>
        <JsonSchemaComponents.json_schema_node
          :if={@schema_version}
          field={@form[:content]}
          schema={@schema_version.content.properties.credential_subject.properties.content}
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
  def update(%{credential: credential} = assigns, socket) do
    changeset = change_credential(credential)

    {:ok,
     socket
     |> assign(assigns)
     |> update_schema_options()
     |> assign(:schema_version, nil)
     |> assign_new(:form, fn ->
       to_form(changeset, as: "credential")
     end)}
  end

  @impl true
  def handle_event("autocomplete_schemas", %{"query" => query}, socket) do
    {:noreply, update_schema_options(socket, query)}
  end

  def handle_event("validate", %{"credential" => credential_params}, socket) do
    schema_version_id = Map.get(credential_params, "schema_version_id")
    schema_version = find_schema_option(schema_version_id, socket)
    changeset = change_credential(socket.assigns.credential, credential_params)

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate, as: "credential"))
     |> assign(:schema_version, schema_version)}
  end

  def handle_event("save", %{"credential" => credential_params}, socket) do
    credential_params = complete_credential(credential_params, socket)

    case Credentials.create_credential(:user, credential_params) do
      {:ok, credential} ->
        notify_parent({:saved, credential})

        {:noreply,
         socket
         |> push_patch(to: socket.assigns.patch)
         |> put_flash(:info, dgettext("credentials", "creation_succeded"))}

      {:error, changeset} ->
        IO.inspect(changeset)

        {:noreply,
         socket
         |> put_flash(:error, dgettext("credentials", "creation_failed"))}
    end
  end

  defp change_credential(credential, attrs \\ %{}) do
    types = %{
      schema_version_id: :string,
      content: :string
    }

    {credential, types}
    |> Ecto.Changeset.cast(attrs, [:schema_version_id, :content])
    |> Ecto.Changeset.validate_required([:schema_version_id, :content],
      message: gettext("field_required")
    )
  end

  defp update_schema_options(socket, query \\ "") do
    options =
      Schemas.list_schema_versions(
        title: query,
        status: :published,
        org_id: socket.assigns.current_user.org_id
      )
      |> Enum.map(fn schema_version ->
        schema_version
        |> Map.merge(%{
          text: schema_version.schema.title,
          name: schema_version.schema.title,
          id: Integer.to_string(schema_version.id)
        })
      end)

    assign(socket, schema_version_options: options)
  end

  defp find_schema_option(schema_version_id, socket) when is_binary(schema_version_id) do
    socket.assigns.schema_version_options
    |> Enum.find(fn opt -> opt.id == schema_version_id end)
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  defp complete_credential(credential_params, socket) do
    user = socket.assigns.current_user
    schema_version = socket.assigns.schema_version
    content = Map.get(credential_params, "content")

    domain_url = NotebookServerWeb.Endpoint.url()

    proof = %{
      "type" => "JsonWebSignature2020",
      "created" => DateTime.utc_now() |> DateTime.to_iso8601(),
      "verification_method" => "#{domain_url}/#{user.org.public_id}/public-key",
      "proof_purpose" => "assertionMethod"
    }

    credential = %{
      "title" => schema_version.schema.title,
      "issuer" => "#{domain_url}/#{user.org.public_id}",
      "credential_subject" => %{
        "id" => "#TODO",
        "content" => content
      },
      "credential_schema" => %{
        "id" => "#{domain_url}/schema-versions/#{schema_version.id}"
      },
      "proof" => proof
    }

    canonical_form = Jason.encode!(credential, pretty: false)

    # jws =
    #  private_key
    #  |> JOSE.JWK.from_pem()
    #  |> JOSE.JWS.sign(canonical_form, %{"alg" => "RS256"})
    #  |> JOSE.JWS.compact()
    #  |> elem(1)

    signed_proof = Map.put(proof, "jws", canonical_form)
    credential = Map.put(credential, "proof", signed_proof)

    %{
      "user_id" => user.id,
      "org_id" => user.org_id,
      "credential" => %{
        "schema_version_id" => String.to_integer(schema_version.id),
        "content" => credential
      }
    }
  end
end

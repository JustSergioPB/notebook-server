defmodule NotebookServer.Schemas do
  alias NotebookServer.Repo
  alias NotebookServer.Schemas.Schema
  alias NotebookServer.Schemas.SchemaVersion
  import Ecto.Query, warn: false

  @doc """
  Returns the list of schemas.

  ## Examples

      iex> list_schemas()
      [%Schema{}, ...]

  """
  def list_schemas(opts \\ []) do
    org_id = Keyword.get(opts, :org_id)
    title = Keyword.get(opts, :title)

    query =
      if !is_nil(org_id),
        do: from(s in Schema, where: s.org_id == ^org_id),
        else: from(s in Schema)

    query =
      if is_binary(title),
        do: from(s in query, where: ilike(s.title, ^"%#{title}%")),
        else: query

    Repo.all(query) |> Repo.preload([:org, schema_versions: schema_versions_query(opts)])
  end

  @doc """
  Gets a single schema.

  Raises `Ecto.NoResultsError` if the Schema does not exist.

  ## Examples

      iex> get_schema!(123)
      %Schema{}

      iex> get_schema!(456)
      ** (Ecto.NoResultsError)

  """
  def get_schema!(id, opts \\ []) do
    Repo.get!(Schema, id) |> Repo.preload([:org, schema_versions: schema_versions_query(opts)])
  end

  @doc """
  Deletes a schema.

  ## Examples

      iex> delete_schema(schema)
      {:ok, %Schema{}}

      iex> delete_schema(schema)
      {:error, %Ecto.Changeset{}}

  """
  def delete_schema(%Schema{} = schema) do
    Repo.delete(schema)
  end

  def create_schema(attrs \\ %{}) do
    %Schema{}
    |> Schema.changeset(attrs)
    |> Repo.insert()
  end

  def update_schema(%Schema{} = schema, attrs) do
    latest_version = schema |> Map.get(:schema_versions) |> Enum.at(0)
    schema_version_attrs = attrs |> get_in(["schema_versions", "0"])

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :update_schema,
      Schema.changeset(schema, attrs, create: false)
    )
    |> insert_or_update_schema_version(latest_version, schema_version_attrs)
    |> Repo.transaction()
  end

  defp insert_or_update_schema_version(multi, %SchemaVersion{} = schema_version, attrs) do
    if schema_version.status == :draft,
      do:
        Ecto.Multi.update(
          multi,
          :update_schema_version,
          SchemaVersion.changeset(schema_version, attrs)
        ),
      else:
        Ecto.Multi.insert(
          multi,
          :create_schema_version,
          SchemaVersion.changeset(%SchemaVersion{}, attrs)
        )
  end

  def change_schema(%Schema{} = schema, attrs \\ %{}) do
    Schema.changeset(schema, attrs)
  end

  def get_schema_version!(id),
    do:
      Repo.get!(SchemaVersion, id)
      |> Repo.preload(:schema)

  def create_schema_version(attrs \\ %{}) do
    %SchemaVersion{}
    |> SchemaVersion.changeset(attrs)
    |> Repo.insert()
  end

  def publish_schema_version(%SchemaVersion{} = schema_version) do
    Ecto.Multi.new()
    |> Ecto.Multi.update_all(
      :old_version,
      from(sv in SchemaVersion,
        where: sv.schema_id == ^schema_version.schema_id and sv.status == :published,
        update: [
          set: [status: :archived]
        ]
      ),
      []
    )
    |> Ecto.Multi.update(:publish_version, SchemaVersion.publish_changeset(schema_version))
    |> Repo.transaction()
  end

  def archive_schema_version(%SchemaVersion{} = schema_version) do
    schema_version
    |> SchemaVersion.archive_changeset()
    |> Repo.update()
  end

  def list_schema_versions(opts \\ []) do
    org_id = opts |> Keyword.get(:org_id)
    title = opts |> Keyword.get(:title)
    status = opts |> Keyword.get(:status)

    query =
      if is_atom(status),
        do: from(sv in SchemaVersion, where: sv.status == ^status),
        else: from(sv in SchemaVersion)

    query =
      if is_binary(title),
        do:
          from(sv in query,
            left_join: s in Schema,
            on: sv.schema_id == s.id,
            where: ilike(s.title, ^"%#{title}%")
          ),
        else: query

    query =
      if is_integer(org_id),
        do:
          from(sv in query,
            left_join: s in Schema,
            on: sv.schema_id == s.id,
            where: s.org_id == ^org_id
          ),
        else: query

    Repo.all(query) |> Repo.preload(:schema)
  end

  def schema_versions_query(opts \\ []) do
    amount = Keyword.get(opts, :amount, :latest)

    case amount do
      :latest -> from(sv in SchemaVersion, order_by: [desc: sv.inserted_at], limit: 1)
      # TODO: this doesn't work for archived schemas
      :semi -> from(sv in SchemaVersion, order_by: [desc: sv.inserted_at], limit: 2)
      :all -> from(sv in SchemaVersion, order_by: [desc: sv.inserted_at])
    end

    # TODO: fix this
    from(sv in SchemaVersion, order_by: [desc: sv.inserted_at])
  end
end

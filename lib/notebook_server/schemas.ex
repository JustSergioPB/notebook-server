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
    latest? = Keyword.get(opts, :latest, false)

    query =
      if !is_nil(org_id),
        do: from(s in Schema, where: s.org_id == ^org_id),
        else: from(s in Schema)

    query =
      if is_binary(title),
        do: from(s in query, where: ilike(s.title, ^"%#{title}%")),
        else: query

    sub_query =
      if latest?,
        do: from(sv in SchemaVersion, order_by: [desc: sv.version], limit: 1),
        else: from(sv in SchemaVersion, order_by: [desc: sv.version])

    Repo.all(query) |> Repo.preload([:org, schema_versions: sub_query])
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
    latest? = Keyword.get(opts, :latest, false)

    query =
      if latest?,
        do: from(sv in SchemaVersion, order_by: [desc: sv.version], limit: 1),
        else: from(sv in SchemaVersion, order_by: [desc: sv.version])

    Repo.get!(Schema, id) |> Repo.preload([:org, schema_versions: query])
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
    latest_version =
      schema |> Map.get(:schema_versions) |> Enum.sort_by(& &1.version, :desc) |> Enum.at(0)

    latest_is_in_draft? = is_map(latest_version) && latest_version.status == :draft

    schema_version_attrs = attrs |> get_in(["schema_versions", "0"])

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :update_schema,
      Schema.changeset(schema, attrs, create: latest_is_in_draft?)
    )
    |> maybe_insert_schema_version(schema_version_attrs, latest_is_in_draft?)
    |> Repo.transaction()
    |> case do
      {:ok, %{update_schema: schema}} -> {:ok, schema}
      {:error, :update_schema, changeset, _} -> {:error, :update_schema, changeset}
      {:error, :create_schema_version, _, _} -> {:error, :create_schema_version}
    end
  end

  def maybe_insert_schema_version(multi, attrs, latest_is_in_draft?)
      when latest_is_in_draft? != true do
    multi
    |> Ecto.Multi.run(:create_schema_version, fn _, _ ->
      create_schema_version(attrs)
    end)
  end

  def maybe_insert_schema_version(multi, _, _), do: multi

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
    |> case do
      {:ok, %{publish_version: schema_version}} ->
        {:ok, schema_version}

      {:error, :publish_version, changeset, _} ->
        {:error, :publish_version, changeset}

      {:error, :old_version, _, _} ->
        {:error, :old_version}
    end
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
end

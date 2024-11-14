defmodule NotebookServer.Schemas do
  import Ecto.Query, warn: false
  alias NotebookServer.Repo

  alias NotebookServer.Schemas.Schema
  alias NotebookServer.Schemas.SchemaVersion
  use Gettext, backend: NotebookServerWeb.Gettext

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

    Repo.all(query)
    |> Repo.preload([
      :org,
      schema_versions: from(sv in SchemaVersion, order_by: sv.version_number)
    ])
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
  def get_schema!(id),
    do:
      Repo.get!(Schema, id)
      |> Repo.preload([
        :org,
        schema_versions: from(sv in SchemaVersion, order_by: sv.version_number)
      ])

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
    org_id = attrs |> Map.get("org_id")
    title = attrs |> Map.get("title")

    Ecto.Multi.new()
    |> Ecto.Multi.insert(
      :schema,
      Schema.changeset(%Schema{}, %{org_id: org_id, title: title})
    )
    |> Ecto.Multi.insert(:schema_version, fn %{schema: schema} ->
      attrs =
        attrs
        |> Map.merge(%{
          "schema_id" => schema.id,
          "version_number" => 0
        })

      SchemaVersion.changeset(%SchemaVersion{}, attrs)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{schema: schema, schema_version: schema_version}} ->
        {:ok, schema, schema_version}

      {:error, :schema, changeset, _} ->
        {:error, changeset, gettext("error_while_creating_schema")}

      {:error, :schema_version, changeset, _} ->
        {:error, changeset, gettext("error_while_creating_schema_version")}
    end
  end

  def update_schema(%SchemaVersion{} = schema_version, attrs) do
    title = attrs |> Map.get("title")
    org_id = schema_version |> Map.get(:org_id)
    schema_id = schema_version |> Map.get(:schema_id)

    Ecto.Multi.new()
    |> Ecto.Multi.update(
      :schema,
      Schema.changeset(%Schema{id: schema_id, org_id: org_id}, %{title: title})
    )
    |> insert_or_update_schema_version(schema_version, attrs)
    |> Repo.transaction()
    |> case do
      {:ok, %{schema: schema, schema_version: schema_version}} ->
        {:ok, schema, schema_version}

      {:error, :schema, changeset, _} ->
        {:error, changeset, gettext("error_while_updating_schema")}

      {:error, :schema_version, changeset, _} ->
        {:error, changeset, gettext("error_while_creating_schema_version")}
    end
  end

  def get_schema_version!(id),
    do:
      Repo.get!(SchemaVersion, id)
      |> Repo.preload(:schema)

  def publish_schema_version(id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:schema_version, fn %{} ->
      from(sv in SchemaVersion,
        where: sv.id == ^id
      )
    end)
    |> Ecto.Multi.update_all(
      :old_version,
      fn %{schema_version: schema_version} ->
        from(sv in SchemaVersion,
          where: sv.schema_id == ^schema_version.schema_id and sv.status == :published,
          update: [
            set: [status: :archived]
          ]
        )
      end,
      []
    )
    |> Ecto.Multi.update(:new_version, fn %{schema_version: schema_version} ->
      SchemaVersion.publish_changeset(schema_version)
    end)
    |> Repo.transaction()
    |> case do
      {:ok,
       %{schema_version: _schema_version, old_version: _old_version, new_version: new_version}} ->
        {:ok, new_version}

      {:error, :schema_version, _changeset, _} ->
        {:error, gettext("schema_version_not_found")}

      {:error, :old_version, _changeset, _} ->
        {:error, gettext("error_while_archiving_old_version")}

      {:error, :new_version, _changeset, _} ->
        {:error, gettext("error_while_publishin_new_version")}
    end
  end

  def archive_schema_version(id) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(:schema_version, fn %{} ->
      from(sv in SchemaVersion,
        where: sv.id == ^id
      )
    end)
    |> Ecto.Multi.update(:archived_version, fn %{schema_version: schema_version} ->
      SchemaVersion.archive_changeset(schema_version)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{schema_version: _schema_version, archived_version: archived_version}} ->
        {:ok, archived_version}

      {:error, :schema_version, _changeset, _} ->
        {:error, gettext("schema_version_not_found")}

      {:error, :archived_version, _changeset, _} ->
        {:error, gettext("error_while_archiving_old_version")}
    end
  end

  def change_schema_version(%SchemaVersion{} = schema_version, attrs \\ %{}) do
    SchemaVersion.changeset(schema_version, attrs)
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

  defp insert_or_update_schema_version(multi, schema_version, attrs) do
    status = schema_version |> Map.get(:status)
    version_number = schema_version |> Map.get(:version_number)

    multi =
      if status == :draft do
        multi
        |> Ecto.Multi.update(:schema_version, SchemaVersion.changeset(schema_version, attrs))
      else
        multi
        |> Ecto.Multi.insert(:schema_version, fn %{schema: schema} ->
          attrs =
            attrs
            |> Map.merge(%{
              "schema_id" => schema.id,
              "version_number" => version_number + 1
            })

          SchemaVersion.changeset(%SchemaVersion{}, attrs)
        end)
      end

    multi
  end
end

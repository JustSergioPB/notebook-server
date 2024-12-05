defmodule NotebookServer.Schemas.SchemaForm do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "schema_forms" do
    field :title, :string
    field :description, :string

    embeds_many :rows, Row, on_replace: :delete do
      embeds_many :columns, Column, on_replace: :delete do
        field :title, :string, default: "Texto"
        field :input, Ecto.Enum, values: [:text, :number, :integer, :checkbox], default: :text
        field :min_length, :integer, default: 2
        field :max_length, :integer, default: 50
        field :pattern, :string
      end
    end
  end

  def changeset(schema_form, attrs \\ %{}) do
    schema_form
    |> cast(attrs, [:title, :description])
    |> validate_required([:title], message: gettext("field_required"))
    |> validate_length(:title,
      min: 2,
      max: 50,
      message: dgettext("schemas", "title_length %{max} %{min}", min: 2, max: 50)
    )
    |> validate_length(:description,
      min: 2,
      max: 255,
      message: dgettext("schemas", "title_length %{max} %{min}", min: 2, max: 255)
    )
    |> cast_embed(:rows,
      with: &row_changeset/2,
      sort_param: :row_sort,
      drop_param: :row_drop
    )
  end

  def row_changeset(row, attrs \\ %{}) do
    row
    |> cast(attrs, [])
    |> cast_embed(:columns,
      with: &col_changeset/2,
      sort_param: :col_sort,
      drop_param: :col_drop
    )
  end

  def col_changeset(col, attrs \\ %{}) do
    col
    |> cast(attrs, [:title, :max_length, :min_length, :input, :pattern])
    |> validate_required([:title, :input], message: gettext("field_required"))
  end
end

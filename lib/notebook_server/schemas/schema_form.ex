defmodule NotebookServer.Schemas.SchemaForm do
  use Ecto.Schema
  import Ecto.Changeset
  use Gettext, backend: NotebookServerWeb.Gettext

  schema "schema_forms" do
    field :title, :string
    field :description, :string

    embeds_many :content, Content, on_replace: :delete do
      field :title, :string, default: "Campo"
      field :input, Ecto.Enum, values: [:text, :number, :integer, :checkbox], default: :text
      field :min_length, :integer, default: 2
      field :max_length, :integer, default: 50
      field :pattern, :string
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
    |> cast_embed(:content,
      with: &content_changeset/2,
      sort_param: :content_sort,
      drop_param: :content_drop
    )
  end

  def content_changeset(content, attrs \\ %{}) do
    content
    |> cast(attrs, [:title, :max_length, :min_length, :input, :pattern])
    |> validate_required([:title, :input], message: gettext("field_required"))
  end
end

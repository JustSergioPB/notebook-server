defmodule NotebookServerWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use NotebookServerWeb, :html
  use Gettext, backend: NotebookServerWeb.Gettext

  embed_templates "page_html/*"
end

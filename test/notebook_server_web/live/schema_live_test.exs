defmodule NotebookServerWeb.SchemaLiveTest do
  use NotebookServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import NotebookServer.CredentialsFixtures

  @create_attrs %{context: %{}}
  @update_attrs %{context: %{}}
  @invalid_attrs %{context: nil}

  defp create_schema(_) do
    schema = schema_fixture()
    %{schema: schema}
  end

  describe "Index" do
    setup [:create_schema]

    test "lists all schemas", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/schemas")

      assert html =~ "Listing Schemas"
    end

    test "saves new schema", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/schemas")

      assert index_live |> element("a", "New Schema") |> render_click() =~
               "New Schema"

      assert_patch(index_live, ~p"/schemas/new")

      assert index_live
             |> form("#schema-form", schema: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#schema-form", schema: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/schemas")

      html = render(index_live)
      assert html =~ "Schema created successfully"
    end

    test "updates schema in listing", %{conn: conn, schema: schema} do
      {:ok, index_live, _html} = live(conn, ~p"/schemas")

      assert index_live |> element("#schemas-#{schema.id} a", "Edit") |> render_click() =~
               "Edit Schema"

      assert_patch(index_live, ~p"/schemas/#{schema}/edit")

      assert index_live
             |> form("#schema-form", schema: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#schema-form", schema: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/schemas")

      html = render(index_live)
      assert html =~ "Schema updated successfully"
    end

    test "deletes schema in listing", %{conn: conn, schema: schema} do
      {:ok, index_live, _html} = live(conn, ~p"/schemas")

      assert index_live |> element("#schemas-#{schema.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#schemas-#{schema.id}")
    end
  end

  describe "Show" do
    setup [:create_schema]

    test "displays schema", %{conn: conn, schema: schema} do
      {:ok, _show_live, html} = live(conn, ~p"/schemas/#{schema}")

      assert html =~ "Show Schema"
    end

    test "updates schema within modal", %{conn: conn, schema: schema} do
      {:ok, show_live, _html} = live(conn, ~p"/schemas/#{schema}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Schema"

      assert_patch(show_live, ~p"/schemas/#{schema}/show/edit")

      assert show_live
             |> form("#schema-form", schema: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#schema-form", schema: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/schemas/#{schema}")

      html = render(show_live)
      assert html =~ "Schema updated successfully"
    end
  end
end

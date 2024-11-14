defmodule NotebookServerWeb.BridgeLiveTest do
  use NotebookServerWeb.ConnCase

  import Phoenix.LiveViewTest
  import NotebookServer.BridgesFixtures

  @create_attrs %{active: true, name: "some name"}
  @update_attrs %{active: false, name: "some updated name"}
  @invalid_attrs %{active: false, name: nil}

  defp create_bridge(_) do
    bridge = bridge_fixture()
    %{bridge: bridge}
  end

  describe "Index" do
    setup [:create_bridge]

    test "lists all bridges", %{conn: conn, bridge: bridge} do
      {:ok, _index_live, html} = live(conn, ~p"/bridges")

      assert html =~ "Listing Bridges"
      assert html =~ bridge.name
    end

    test "saves new bridge", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/bridges")

      assert index_live |> element("a", "New Bridge") |> render_click() =~
               "New Bridge"

      assert_patch(index_live, ~p"/bridges/new")

      assert index_live
             |> form("#bridge-form", bridge: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bridge-form", bridge: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bridges")

      html = render(index_live)
      assert html =~ "Bridge created successfully"
      assert html =~ "some name"
    end

    test "updates bridge in listing", %{conn: conn, bridge: bridge} do
      {:ok, index_live, _html} = live(conn, ~p"/bridges")

      assert index_live |> element("#bridges-#{bridge.id} a", "Edit") |> render_click() =~
               "Edit Bridge"

      assert_patch(index_live, ~p"/bridges/#{bridge}/edit")

      assert index_live
             |> form("#bridge-form", bridge: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#bridge-form", bridge: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/bridges")

      html = render(index_live)
      assert html =~ "Bridge updated successfully"
      assert html =~ "some updated name"
    end

    test "deletes bridge in listing", %{conn: conn, bridge: bridge} do
      {:ok, index_live, _html} = live(conn, ~p"/bridges")

      assert index_live |> element("#bridges-#{bridge.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#bridges-#{bridge.id}")
    end
  end

  describe "Show" do
    setup [:create_bridge]

    test "displays bridge", %{conn: conn, bridge: bridge} do
      {:ok, _show_live, html} = live(conn, ~p"/bridges/#{bridge}")

      assert html =~ "Show Bridge"
      assert html =~ bridge.name
    end

    test "updates bridge within modal", %{conn: conn, bridge: bridge} do
      {:ok, show_live, _html} = live(conn, ~p"/bridges/#{bridge}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Bridge"

      assert_patch(show_live, ~p"/bridges/#{bridge}/show/edit")

      assert show_live
             |> form("#bridge-form", bridge: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#bridge-form", bridge: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/bridges/#{bridge}")

      html = render(show_live)
      assert html =~ "Bridge updated successfully"
      assert html =~ "some updated name"
    end
  end
end

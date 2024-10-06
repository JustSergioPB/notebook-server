defmodule NotebookServerWeb.Plugs.SetLocale do
  # 1
  import Plug.Conn
  # 2
  @supported_locales Gettext.known_locales(NotebookServerWeb.Gettext)

  # 3
  def init(_options), do: nil
  #  4
  def call(%Plug.Conn{params: %{"locale" => locale}} = conn, _options)
      when locale in @supported_locales do
    LokaliseDemoWeb.Gettext |> Gettext.put_locale(locale)
    conn |> put_resp_cookie("stamp_locale", locale, max_age: 365 * 24 * 60 * 60)
  end

  # 5
  def call(conn, _options) do
    case fetch_locale_from(conn) do
      nil ->
        conn

      locale ->
        LokaliseDemoWeb.Gettext |> Gettext.put_locale(locale)
        conn |> put_resp_cookie("locale", locale, max_age: 365 * 24 * 60 * 60)
    end
  end

  defp fetch_locale_from(conn) do
    (conn.params["locale"] || conn.cookies["stamp_locale"]) |>
    check_locale
  end

  defp check_locale(locale) when locale in @supported_locales, do: locale

  defp check_locale(_), do: nil
end

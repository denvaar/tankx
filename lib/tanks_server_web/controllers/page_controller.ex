defmodule TanksServerWeb.PageController do
  use TanksServerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

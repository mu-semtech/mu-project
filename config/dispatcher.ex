defmodule Dispatcher do
  use Plug.Router

  def start(_argv) do
    port = 80
    IO.puts "Starting Plug with Cowboy on port #{port}"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port
    :timer.sleep(:infinity)
  end

  plug Plug.Logger
  plug :match
  plug :dispatch

  get "/hello" do
    send_resp( conn, 200, "world" )
  end

  get "/world" do
    send_resp( conn, 200, "42" )
  end

  get "/" do
    send_resp( conn, 200, "This is plug" )
  end

  match "/accounts/*path" do
    Proxy.forward conn, path, "http://registration/accounts"
  end

  match "/session/*path" do
    # eg: POST /session/logout
    Proxy.forward conn, path, "http://login/"
  end

  match "/comments/*path" do
    IO.puts "Matching /comments/*path"
    Proxy.forward conn, path, "http://comments/"
  end

  match "/files/*path" do
    Proxy.forward conn, path, "http://file/files"
  end

  match _ do
    send_resp( conn, 404, "Route not found" )
  end

end

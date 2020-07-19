defmodule Dispatcher do
  use Matcher
  define_accept_types [
    json: [ "application/json", "application/vnd.api+json" ]
  ]

  @json %{ accept: %{ json: true } }

  match "/*_", %{ last_call: true } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end
end

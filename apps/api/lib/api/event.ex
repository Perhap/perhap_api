defmodule API.Event do
  import Plug.Conn

  def post(conn) do
    json = conn.body_params
    send_resp(conn, 204, "")
  end

  def bulk(conn) do
    send_resp(conn, 204, "")
  end
  
end

defmodule API.Event do
  import Plug.Conn

  @spec post(Plug.Conn, DB.Event.t) :: Plug.Conn
  def post(conn, %DB.Event{} = event) do
    case DB.Event.save(%{event | meta: conn.body_params}) do
      %DB.Event{}=event ->
        send_resp(conn, 204, "")
      _ -> send_resp(conn, 500, "General Error")
    end
  end

  def bulk(conn) do
    send_resp(conn, 204, "")
  end

end

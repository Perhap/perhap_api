defmodule API.Response do
  import Plug.Conn

  alias API.Error, as: E

  def send(conn, %API.Error{} = error) do
    conn |> send(error.http_code, E.format(error))
  end

  def send(conn, 204) do
    send_resp(conn, 204, "")
  end

  def send(conn, status, response_term) do
    {:ok, json, crc32} = make(response_term)
    conn |>
      put_resp_header("content-type", "application/json") |>
      put_resp_header("x-bigsquid-crc32", Integer.to_string(crc32)) |>
    send_resp(status, json)
  end

  defp make(data) do
    json = Poison.encode!(data)
    crc32 = :erlang.crc32(json)
    {:ok, json, crc32}
  end

end

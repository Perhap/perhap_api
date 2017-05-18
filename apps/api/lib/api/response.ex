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
  
  defp make(map) when is_map(map) do
    json = Poison.encode!(map)
    makeCRC(json)
  end
  defp make(list) when is_list(list) do
    json = case Keyword.keyword?(list) do
      true -> JSON.encode!(list)
      false -> Poison.encode!(list)
    end
    makeCRC(json)
  end
  defp make(json) when is_binary(json) do
    makeCRC(json)
  end
  defp makeCRC(data) when is_binary(data) do
    crc32 = :erlang.crc32(data)
    {:ok, data, crc32}
  end

end

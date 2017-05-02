defmodule Stats do
  alias API.Response
  alias :exometer, as: Exometer
  alias :event_get, as: E_Get
  alias :event_post, as: E_Post

  def get(conn) do
    stats = (c_stat(Exometer.get_value(["event", "GET", :counter], :value), E_Get) |||
             c_stat(Exometer.get_value(["event", "GET", :spiral], :one), E_Get) |||
             c_stat(Exometer.get_value(["event", "GET", :histogram]), E_Get) |||
             c_stat(Exometer.get_value(["event", "POST", :counter], :value), E_Post) |||
             c_stat(Exometer.get_value(["event", "POST", :spiral], :one), E_Post) |||
             c_stat(Exometer.get_value(["event", "POST", :histogram]), E_Post))

    Response.send(conn, 200, stats)
  end

  defp c_stat({:error, :not_found}, _), do: %{}
  defp c_stat({:ok, list}, stat_key) do
    Enum.into(Enum.map(list, fn({k,v}) ->
      new_k = case is_atom(k) do
        true ->
          Atom.to_string(stat_key) <> "_" <> Atom.to_string(k)
        false ->
          Atom.to_string(stat_key) <> "_" <> Integer.to_string(k)
      end
      {new_k, v}
    end), %{})
  end

  defp a ||| b do
    Map.merge(a, b)
  end
end

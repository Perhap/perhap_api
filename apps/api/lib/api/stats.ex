defmodule Stats do
  alias API.Response
  alias :exometer, as: Exometer
  alias :event_get, as: E_Get
  alias :event_post, as: E_Post
  alias :model_get, as: M_Get

  def get(conn) do
    stats = collect_stats() |> Enum.sort |> Enum.flat_map(fn({k,v}) -> ["#{k}": v] end)
    Response.send(conn, 200, stats)
  end

  def collect_stats() do
    (c_stat(Exometer.get_value(["event", "GET", :counter], :value), E_Get) |||
     c_stat(Exometer.get_value(["event", "GET", :spiral], :one), E_Get) |||
     c_stat(Exometer.get_value(["event", "GET", :histogram]), E_Get) |||
     c_stat(Exometer.get_value(["event", "POST", :counter], :value), E_Post) |||
     c_stat(Exometer.get_value(["event", "POST", :spiral], :one), E_Post) |||
     c_stat(Exometer.get_value(["event", "POST", :histogram]), E_Post) |||
     c_stat(Exometer.get_value(["model", "GET", :counter], :value), M_Get) |||
     c_stat(Exometer.get_value(["model", "GET", :spiral], :one), M_Get) |||
     c_stat(Exometer.get_value(["model", "GET", :histogram]), M_Get) |||
     %{"total_events" => DB.Event.hll_stat("events")} |||
     %{"total_entities" => DB.Event.hll_stat("entities")} |||
     %{"total_domains" => DB.Event.hll_stat("domains")} |||
     %{"total_realms" => DB.Event.hll_stat("realms")})
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

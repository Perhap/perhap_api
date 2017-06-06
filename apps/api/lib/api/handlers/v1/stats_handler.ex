alias API.Stats
alias API.Error, as: E
alias API.Response

defmodule API.StatsHandler do
  use API.Handler
  def init(req0, opts) do
    method = :cowboy_req.method(req0)
    {:ok, handle(method, nil, req0), opts}
  end

  def handle("GET", _, req0) do
    Stats.get(req0)
  end
  def handle(_, _, req0) do
    req0 |> Response.send(E.make(:not_found))
  end
end

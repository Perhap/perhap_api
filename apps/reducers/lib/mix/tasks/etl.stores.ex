defmodule Mix.Tasks.Etl.Stores do
  use Mix.Task
  @shortdoc "Transform Store Data"
  @preferred_cli_env :dev

  require Logger
  
  def run(_argv) do
    Application.ensure_all_started(:db)
    IO.puts ("MIX ENV: #{Mix.env}; #{inspect(self())}")
    # Other Interesting Keys
    # service = "domo"
    # entity_id = "ea43de77-366f-4758-a8cc-f27bf9f622b9"
    # entity_id = "9f3f1763-d2e8-45cd-8e5c-89ff038a95f5"
    service = "storeindex"
    entity_id = "100077bd-5b34-41ac-b37b-62adbf86c1a5"
    e_ctx = DB.Common.event_context(%{entity_id: entity_id, domain: service})
    state_key = DB.Reducer.State.key(e_ctx, service)

    # store_index
    _stores = case DB.Reducer.State.find(state_key) do
      :not_found -> :done
      state ->
        state.model.data["stores"] |>
          Enum.map(fn {_k,v} -> v end) |> Enum.each(fn (key) ->
            # for each store, do a function
            e_ctx = DB.Common.event_context(%{entity_id: key, domain: "stats"})
            delete_key = DB.Reducer.State.key(e_ctx, "stats")
            DB.Reducer.State.delete(delete_key)
            Logger.info("Deleted: stats/#{key}")
          end)
    end

  end
end

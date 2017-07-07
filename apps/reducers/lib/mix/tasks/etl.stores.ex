defmodule Mix.Tasks.Etl.Stores do
  use Mix.Task
  @shortdoc "Transform Store Data"
  @preferred_cli_env :dev

  require Logger
  alias DB.Reducer.State

  def get_store_key(entity_id) do
    e_ctx = DB.Common.event_context(%{entity_id: entity_id, domain: "stats"})
    DB.Reducer.State.key(e_ctx, "stats")
  end

  def run(["delete"]) do
    Application.ensure_all_started(:db)
    IO.puts ("MIX ENV: #{Mix.env}; #{inspect(self())}")
    service = "storeindex"
    entity_id = "100077bd-5b34-41ac-b37b-62adbf86c1a5"
    e_ctx = DB.Common.event_context(%{entity_id: entity_id, domain: service})
    state_key = DB.Reducer.State.key(e_ctx, service)

    # store_index
    _stores = case DB.Reducer.State.find(state_key) do
      :not_found -> :done
      state ->
        state.model.data["stores"] |>
          Enum.each(fn {_store_num, entity_id} ->
            # for each store, delete stats
            store_key = get_store_key(entity_id)
            apply(__MODULE__, :delete_store_stats, [store_key])
          end)
    end

  end


  def run([transform, module, func]) do
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
          Enum.each(fn {store_num, entity_id} ->
            # for each store, do a function
            store_key = get_store_key(entity_id)
            apply(__MODULE__, :transform, [store_key, store_num, module, func])
          end)
    end
  end

  # transforms stores state, then saves results
  def transform(store_key, store_num, module, transformer)do
    _stores = case DB.Reducer.State.find(store_key) do
      :not_found -> :done
      state ->
        new_state = apply(module, transformer, [state.model.data, store_num])
        DB.Reducer.State.save( %State{state_id: store_key, data: new_state})
        Logger.debug("saved updated state for store #{store_num}")
    end
  end

  def log_state(model, num)do
    Logger.debug("Store num #{num} and #{inspect(model)}")
  end

  def delete_store_stats(store_key)do
    DB.Reducer.State.delete(store_key)
    Logger.info("Deleted: stats/#{store_key}")
  end

end

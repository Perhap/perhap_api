defmodule Mix.Tasks.Etl.Stores do
  use Mix.Task
  @shortdoc "Transform Store Data"
  @preferred_cli_env :dev

  alias DB.Common
  alias DB.Reducer.State

  def run(argv) do
    Application.ensure_all_started(:db)
    IO.puts ("MIX ENV: #{Mix.env}; #{inspect(self())}")
    {options, _, _} = OptionParser.parse(argv)
    case options do
      [delete: true] -> execute(:delete)
      [transform: transform_fun] ->
        function = String.to_atom(transform_fun)
        has_function = __MODULE__.module_info |> Keyword.get(:exports) |> Keyword.has_key?(function)
        case has_function do
          false -> IO.puts "Invalid Transform Function, (try log_state)"
          true -> execute(:transform, function)
        end
      _ -> IO.puts "Invalid Operation, (try --delete or --transform)"
    end
    IO.puts "All Done"
  end

  defp get_store_key(entity_id) do
    e_ctx = Common.event_context(%{entity_id: entity_id, domain: "stats"})
    State.key(e_ctx, "stats")
  end

  defp lookup_store_index() do
    service = "storeindex"
    entity_id = "100077bd-5b34-41ac-b37b-62adbf86c1a5"
    e_ctx = Common.event_context(%{entity_id: entity_id, domain: service})
    State.key(e_ctx, service)
  end

  defp execute(operation, transform_fun \\ nil) do
    state_key = lookup_store_index()

    case State.find(state_key) do
      :not_found -> :done
      state ->
        state.model.data["stores"] |>
          Enum.each(fn {store_num, entity_id} ->
            store_key = get_store_key(entity_id)
            case operation do
              :delete -> delete_store_stats(store_key)
              :transform -> transform(store_key, store_num, transform_fun)
              _ -> :invalid_operation
            end
          end)
    end
  end

  defp transform(store_key, store_num, function) when is_atom(function) do
    case State.find(store_key) do
      :not_found -> :ok
      state ->
        case apply(__MODULE__, function, [state.model.data, store_num]) do
          nil -> :ok
          new_state ->
            State.save( %State{state_id: store_key, data: new_state})
            IO.puts ("saved updated state for store #{store_num}")
            :ok
        end
    end
  end

  # simple transform function which justs lists state
  # a real function would inspect and mutate the model
  #
  # calling function will mutate state with whatever map is returned.
  @spec log_state(map(), String.t) :: map() | nil
  def log_state(model, num)do
    IO.puts "Store num #{num} and #{inspect(model)}"
    nil
  end

  defp delete_store_stats(store_key)do
    State.delete(store_key)
    IO.puts ("Deleted: stats/#{store_key}")
    :ok
  end

end

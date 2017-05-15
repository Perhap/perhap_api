defmodule DB.Reducer.State do
  import DB.Common
  require Logger

  defstruct state_id: "",
            data: %{},
            kv: "",
            kv_time: ""

  @type t :: %DB.Reducer.State{state_id: String.t}

  @bucket "reducer_state"

  @spec save(DB.Reducer.State.t) :: DB.Reducer.State.t | :error
  def save(%DB.Reducer.State{state_id: state_id} = state) do
    bucket = namespace(@bucket)
    key = state_id
    kv_info = "#{bucket}/#{key}"
    state = %{state | kv: kv_info}
    try do
      r_object = Riak.Object.create(
        bucket: bucket,
        key: key,
        data: Poison.encode!(state))
      |> Riak.put
      Logger.debug("Saved: #{r_object.bucket}/#{r_object.key}")
      state
    rescue
      error ->
        Logger.error("Problem writing reducer state: #{inspect(error)}")
        :error
    end
  end

  @spec delete(String.t) :: :ok | :error
  def delete(state_id) do
    case Riak.delete(namespace(@bucket), state_id) do
      :ok -> :ok
      error ->
        Logger.error("Problem deleting reducer state: #{inspect(error)}")
        :error
    end
  end

  @spec find(String.t, boolean()) :: DB.Common.r_json_t | :not_found | :error
  def find(key, include_db_attrs \\ false) do
    result = try do
      Riak.find(namespace(@bucket), key)
    rescue
      error ->
        Logger.error("Problem reading reducer state: #{inspect(error)}")
        :error
    end
    case result do
      nil -> :not_found
      :error -> :error
      _ ->
        case include_db_attrs do
          true -> DB.Common.add_db_attrs(result, %DB.Reducer.State{})
          false -> %{model: Poison.decode!(result.data, as: %DB.Reducer.State{})}
        end
    end
  end

end

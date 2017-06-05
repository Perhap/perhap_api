defmodule DB.Reducer.State do
  import DB.Common

  alias DB.Common
  alias DB.Reducer.State
  alias DB.Event

  require Logger

  defstruct state_id: "",
            data: %{},
            kv: ""

  @type t :: %State{state_id: String.t}

  @bucket "reducer_state"

  @spec key(String.t, String.t) :: String.t
  def key(e_ctx, domain) do
    e_ctx <> Common.unit_separator() <> "service.#{domain}"
  end

  @spec save(State.t) :: State.t | :error
  def save(%State{state_id: state_id} = state) when is_binary(state_id) do
    bucket = namespace(@bucket)
    key = state_id
    kv_info = "#{bucket}/#{key}"
    state = %{state | kv: kv_info}
    try do
      json = case Poison.encode(state, strict_keys: true) do
        # this happens if reducers use atoms for keys in state
        # https://github.com/devinus/poison#key-validation
        {:error, {:invalid, term}} -> raise "Invalid JSON Term: #{term}"
        {_, json} -> json
      end
      r_object = Riak.Object.create(
        bucket: bucket,
        key: key,
        data: json) |> Riak.put
      Logger.debug("Saved: #{r_object.bucket}/#{r_object.key}")
      state
    rescue
      error ->
        Logger.error("Problem writing reducer state: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
  end

  @spec delete(String.t) :: :ok | :error
  def delete(state_id) when is_binary(state_id)  do
    case Riak.delete(namespace(@bucket), state_id) do
      :ok -> :ok
      error ->
        Logger.error("Problem deleting reducer state: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
  end

  @spec find(String.t, boolean()) :: DB.Common.r_json_t | :not_found | :error
  def find(key, include_db_attrs \\ false) when is_binary(key) do
    result = try do
      Riak.find(namespace(@bucket), key)
    rescue
      error ->
        Logger.error("Problem reading reducer state: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
    case result do
      nil -> :not_found
      :error -> :error
      _ ->
        case include_db_attrs do
          true -> DB.Common.add_db_attrs(result, %State{})
          false -> %{model: Poison.decode!(result.data, [as: %State{}])}
        end
    end
  end

  @spec reducer_context(list(Event.t)) :: %{required(String.t) => list(Event.t)}
  def reducer_context(events) when is_list(events) do
    Enum.group_by(events, &Common.event_context(&1))
  end

  @spec split_key(String.t) :: {String.t, String.t, String.t}
  def split_key(reducer_state_key) when is_binary(reducer_state_key) do
    [domain, entity_id, service] = String.split(reducer_state_key, Common.unit_separator)
    {domain, entity_id, service}
  end

end

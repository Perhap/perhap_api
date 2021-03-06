defmodule DB.Event do
  import DB.Common

  alias DB.Common
  alias DB.Event
  alias Riak.CRDT.Set, as: RS
  alias Riak.CRDT.HyperLogLog, as: HLL

  require Logger

  defstruct event_id: "",
            type: "",
            realm: "",
            domain: "",
            entity_id: "",
            meta: "",
            remote_ip: "",
            kv: "",
            kv_time: "",
            parents: ""

  @type t :: %Event{event_id: String.t}

  @bucket "events"
  @hll_bucket "distinct"

  @spec save(Event.t) :: Event.t | :error
  def save(%Event{event_id: event_id} = event) when is_binary(event_id) do
    bucket = namespace(@bucket)
    key = event_id
    kv_info = "#{bucket}/#{key}"
    event = %{event | kv: kv_info}
    try do
      {_, json} = Poison.encode(event, strict_keys: true)
      r_object = Riak.Object.create(
        bucket: bucket,
        key: key,
        data: json) |> Riak.put
      Task.Supervisor.async(Perhap.TaskSupervisor, fn ->
        update_entity_domain_index(event)
        update_hll(event)
      end)
      Logger.debug("Saved: #{r_object.bucket}/#{r_object.key}")
      event
    rescue
      error ->
        Logger.error("Problem writing event: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
  end

  @spec delete(String.t) :: :ok | :error
  def delete(event_id) when is_binary(event_id) do
    case Riak.delete(namespace(@bucket), event_id) do
      :ok -> :ok
      error ->
        Logger.error("Problem deleting event: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
  end

  @spec find(String.t | list(String.t), boolean()) :: Common.r_json_t | list(Common.r_json_t) | :not_found | :error
  def find(keys, include_db_attrs \\ false) do
    case is_list(keys) do
      true ->
        keys |> Enum.map(&find_event(&1, include_db_attrs))
      false ->
        find_event(keys, include_db_attrs)
    end
  end

  @spec domains(list(Event.t)) :: list(atom())
  def domains(events) when is_list(events) do
    (Enum.map events, &String.to_atom(&1.domain)) |> Enum.uniq
  end

  @spec entities(list(Event.t)) :: list(String.t)
  def entities(events) when is_list(events) do
    (Enum.map events, &(&1.entity_id)) |> Enum.uniq
  end

  @spec find_by_entity_domain(String.t, String.t) :: list(String.t) | :not_found | :error
  def find_by_entity_domain(entity_id, domain) when is_binary(entity_id) and is_binary(domain) do
    result = try do
      Riak.find("set", namespace_index(:bucket), namespace_index(:key, entity_id, domain)) |> RS.value
    rescue
      error ->
        Logger.error("Problem reading events by entity: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
    case result do
      nil -> :not_found
      :error -> :error
      {:error, :nil_object} -> :not_found
      _ -> result
    end
  end

  # this should be used for admin purposes only
  @spec delete_entity_domain_index(String.t, String.t) :: :ok
  def delete_entity_domain_index(entity_id, domain) when is_binary(entity_id) and is_binary(domain) do
    Riak.delete("set", namespace_index(:bucket), namespace_index(:key, entity_id, domain))
  end

  @spec hll_stat(String.t) :: integer() | :not_found | :error
  def hll_stat(key) when is_binary(key) do
    result = try do
      Riak.find("hll", namespace(@hll_bucket), key) |> HLL.value
    rescue
      error ->
        Logger.error("Problem reading HLL Stat: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
    case result do
      nil -> :not_found
      :error -> :error
      _ -> result
    end
  end

  @spec bucket() :: String.t
  def bucket() do
    namespace(@bucket)
  end

  defp namespace_index(:bucket) do
    namespace(@bucket) <> Common.unit_separator <> "index"
  end
  defp namespace_index(:key, entity_id, domain) do
    domain <> Common.unit_separator() <> entity_id
  end

  # called async, don't need a response
  @spec update_entity_domain_index(Event.t) :: :ok
  defp update_entity_domain_index(%Event{domain: domain, entity_id: entity_id, event_id: event_id})
    when is_binary(domain) and is_binary(entity_id) and is_binary(event_id) do
    RS.new
      |> RS.put(event_id)
      |> Riak.update("set", namespace_index(:bucket), namespace_index(:key, entity_id, domain))
  end

  #called async, don't need a response
  @spec update_hll(Event.t) :: :ok | :error
  defp update_hll(%Event{realm: realm, domain: domain,
                         entity_id: entity_id, event_id: event_id})
    when is_binary(realm) and is_binary(domain) and is_binary(entity_id) and is_binary(event_id) do
    HLL.new
     |> HLL.add_element(event_id)
     |> Riak.update("hll", namespace(@hll_bucket), "events")
    HLL.new
     |> HLL.add_element(entity_id)
     |> Riak.update("hll", namespace(@hll_bucket), "entities")
    HLL.new
     |> HLL.add_element(domain)
     |> Riak.update("hll", namespace(@hll_bucket), "domains")
    HLL.new
     |> HLL.add_element(realm)
     |> Riak.update("hll", namespace(@hll_bucket), "realms")
  end

  @spec find_event(String.t, boolean()) :: Common.r_json_t | :not_found | :error
  defp find_event(key, include_db_attrs) when is_binary(key) do
    result = try do
      Riak.find(namespace(@bucket), key)
    rescue
      error ->
        Logger.error("Problem reading event: #{inspect(error)},
                      trace: #{inspect(:erlang.get_stacktrace())}")
        :error
    end
    case result do
      nil -> :not_found
      :error -> :error
      _ ->
        case include_db_attrs do
          true -> Common.add_db_attrs(result, %Event{})
          false -> %{model: Poison.decode!(result.data, as: %Event{})}
        end
    end
  end
end

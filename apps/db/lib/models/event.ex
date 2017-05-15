defmodule DB.Event do
  import DB.Common
  require Logger

  defstruct event_id: "",
            type: "",
            realm: "",
            domain: "",
            entity_id: "",
            meta: "",
            remote_ip: "",
            kv: "",
            kv_time: ""

  @type t :: %DB.Event{event_id: String.t}

  @bucket "events"

  @spec save(DB.Event.t) :: DB.Event.t | :error
  def save(%DB.Event{event_id: event_id} = event) do
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
      Logger.debug("Saved: #{r_object.bucket}/#{r_object.key}")
      event
    rescue
      error ->
        Logger.error("Problem writing event: #{inspect(error)}")
        :error
    end
  end

  @spec delete(String.t) :: :ok | :error
  def delete(event_id) do
    case Riak.delete(namespace(@bucket), event_id) do
      :ok -> :ok
      error ->
        Logger.error("Problem deleting event: #{inspect(error)}")
        :error
    end
  end

  @spec find(String.t, boolean()) :: DB.Common.r_json_t | :not_found | :error
  def find(key, include_db_attrs \\ false) do
    result = try do
      Riak.find(namespace(@bucket), key)
    rescue
      error ->
        Logger.error("Problem reading event: #{inspect(error)}")
        :error
    end
    case result do
      nil -> :not_found
      :error -> :error
      _ ->
        case include_db_attrs do
          true -> DB.Common.add_db_attrs(result, %DB.Event{})
          false -> %{model: Poison.decode!(result.data, as: %DB.Event{})}
        end
    end
  end

  @spec domains(list(DB.Event.t)) :: list(atom())
  def domains(events) when is_list(events) do
    (Enum.map events, &String.to_atom(&1.domain)) |> Enum.uniq
  end

  @spec entities(list(DB.Event.t)) :: list(String.t)
  def entities(events) when is_list(events) do
    (Enum.map events, &(&1.entity_id)) |> Enum.uniq
  end

  @spec reducer_context(list(DB.Event.t)) :: %{required(String.t) => list(DB.Event.t)}
  def reducer_context(events) when is_list(events) do
    Enum.group_by(events, &DB.Common.event_context(&1))
  end
end

defmodule DB.Event do
  import DB.Common
  require Logger

  defstruct id: "",
            type: "",
            realm: "",
            domain: "",
            entity_id: "",
            meta: "",
            kv: ""

  @type t :: %DB.Event{id: String.t}

  @bucket "events"

  @spec save(DB.Event.t) :: DB.Event.t
  def save(%DB.Event{id: event_id} = event) do
    bucket = namespace(@bucket)
    key = event_id
    kv_info = "#{bucket}/#{key}"
    event = %{event | kv: kv_info}
    r_object = Riak.Object.create(
      bucket: bucket,
      key: key,
      data: Poison.encode!(event))
    |> Riak.put
    Logger.debug("Saved: #{r_object.bucket}/#{r_object.key}")
    event
  end

  @spec find(String.t, boolean()) :: DB.Common.r_event_t | :not_found
  def find(key, include_db_attrs \\ false) do
    result = Riak.find(namespace(@bucket), key)
    case result do
      nil -> :not_found
      _ ->
        case include_db_attrs do
          true -> add_db_attrs(result)
          false -> %{model: Poison.decode!(result.data, as: %DB.Event{})}
        end
    end
  end

  @spec add_db_attrs(%Riak.Object{}) :: DB.Common.r_event_t
  defp add_db_attrs(%Riak.Object{} = r_object) do
    meta = r_object.metadata
    {_, vtag} = :dict.find("X-Riak-VTag", meta)
    {_, {mega,seconds,micro}} = :dict.find("X-Riak-Last-Modified", meta)
    unix = (mega * 1000000 + seconds) * 1000000 + micro
    {:ok, time} = DateTime.from_unix(unix, :microseconds)
    %{model: Poison.decode!(r_object.data, as: %DB.Event{}),
      vtag: vtag,
      last_modify_time: time,
      vclock: r_object.vclock}
  end
end

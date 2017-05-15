defmodule DB.Common do
  @unit_separator Application.get_env(:db, :unit_separator, "\x1f")
  @prefix "#{Mix.env}"

  @type r_json_t :: %{
    required(model: atom) => map(),
    optional(vtag: atom) => String.t,
    optional(last_modify_time: atom) => DateTime.t,
    optional(vclock: atom) => String.t
  }

  def unit_separator do
    @unit_separator
  end

  @spec namespace(String.t) :: String.t
  def namespace(bucket) do
    "#{@prefix}#{@unit_separator}#{bucket}"
  end

  @spec event_context(map()) :: list(String.t)
  def event_context(%{entity_id: entity_id, domain: domain}) do
    domain <> @unit_separator <> entity_id
  end

  @spec add_db_attrs(%Riak.Object{}, map()) :: DB.Common.r_json_t
  def add_db_attrs(%Riak.Object{} = r_object, type) do
    meta = r_object.metadata
    {_, vtag} = :dict.find("X-Riak-VTag", meta)
    {_, {mega,seconds,micro}} = :dict.find("X-Riak-Last-Modified", meta)
    unix = (mega * 1000000 + seconds) * 1000000 + micro
    {:ok, time} = DateTime.from_unix(unix, :microseconds)
    %{model: Poison.decode!(r_object.data, as: type),
      vtag: to_string(vtag),
      last_modify_time: time,
      vclock: Base.encode64(r_object.vclock)}
  end
end

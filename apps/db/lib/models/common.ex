defmodule DB.Common do
  @unit_separator Application.get_env(:db, :unit_separator, "\x1f")
  @prefix "#{Mix.env}"

  @type r_event_t :: %{
    required(model: atom) => DB.Event.t,
    optional(vtag: atom) => String.t,
    optional(last_modify_time: atom) => DateTime.t,
    optional(vclock: atom) => String.t
  }

  @spec namespace(String.t) :: String.t
  def namespace(bucket) do
    "#{@prefix}#{@unit_separator}#{bucket}"
  end
end

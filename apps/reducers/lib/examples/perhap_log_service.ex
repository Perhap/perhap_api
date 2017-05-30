defmodule Service.PerhapLog do
  @behaviour Reducer

  alias DB.Event
  alias Reducer.State
  require Logger

  @domains [:all]
  @types []
  def domains, do: @domains
  def types, do: @types

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, %State{} = state) when is_list(events) do
    events |> Enum.each(&Logger.debug("Event Id: #{&1.event_id}", perhap_only: 1))

    # do stats stuff, handle state conflicts if they exist
    %State{state | new_events: []}
  end
end

defmodule Reducer do
  alias DB.Event
  alias Reducer.State

  @callback types() :: list()
  @callback call(list(Event.t), State.t) :: State.t

end

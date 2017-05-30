defmodule Reducer do
  alias DB.Event
  alias Reducer.State

  @callback domains() :: list(atom())
  @callback types() :: list(atom())
  @callback call(list(Event.t), State.t) :: State.t

end

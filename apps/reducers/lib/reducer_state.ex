defmodule Reducer.State do

  defstruct model: %{},
            new_events: [],
            deferred_events: []

  @type t :: %Reducer.State{}

end

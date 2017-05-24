defmodule TransformerService do

  # API CALL TO STORE INDEX HERE
  def stores do
    %{
      360 => "d68e938f-c597-4ada-9f7a-5bcad3dbbaaf",
      93242 => "8222fa94-8e1f-42a7-b1db-b8ad7b535545",
    }
  end

  def get_entity_id(stores, store_number)do
    stores[store_number]
  end

  def transform_events(events, model)do
     {:ok, model, Enum.map(events, fn(event)-> transform_event(event) end)}
  end

  def transform_event(event)do
    event
    |> Map.put(:domain, "stats")
    |> Map.put(:challenge_id, event[:entity_id])
    |> Map.put(:entity_id, get_entity_id(stores(), event.meta["store_id"]) )
  end

end

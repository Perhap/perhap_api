defmodule Service.StoreIndexTest do
  use ExUnit.Case
  doctest Service.StoreIndex

  alias DB.Event
  alias Reducer.State

  test "the truth" do
    assert 1 + 1 == 2
  end

  setup_all _context do
    {:ok, [
      replace_event: {"replace", %{
        ordered_id: "1-v1-uuid-0-0",
        domain: "store_index",
        entity_id: "uuid-v4",
        data: %{"stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                2 => "81bc429d-d055-4002-a64f-59e1af501236",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978"}
              }
        }
      },
      replace_event2: { "replace", %{
        ordered_id: "2-v1-uuid-0-0",
        domain: "store_index",
        entity_id: "uuid-v4",
        data: %{"stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978",
                4 => "11dec905-a28c-46c9-8572-f68dc6975c91"}
              }
        }
      },
      state_after_replace:
        %State{model: %{"last_played" => "1-v1-uuid-0-0", "stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                2 => "81bc429d-d055-4002-a64f-59e1af501236",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978"}},
          new_events: []},
      state_after_replace2:
        %State{model: %{"last_played" => "2-v1-uuid-0-0", "stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978",
                4 => "11dec905-a28c-46c9-8572-f68dc6975c91"}},
          new_events: []}
    ]}
  end

  def strip(event)do
     Map.put(event, :event_id, "")
  end

  test "validate function" do
    assert(Service.StoreIndex.validate([%{
      domain: "store_index",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-1-0-0",
      kv: "dev_events/uuid-v1-1-0-0",
      meta: %{"stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978"}
             },
      realm: "nike",
      type: "replace",
    },%{
      domain: "store_index",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-1-0-0",
      kv: "dev_events/uuid-v1-1-0-0",
      meta: %{"stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978"}
             },
      realm: "nike",
      type: "replace",
    }]) ==
      [{"replace", %{
        ordered_id: "1-v1-uuid-0-0",
        domain: "store_index",
        entity_id: "uuid-v4",
        data: %{"stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978"}
              }
        }}
      ])
  end

  test "event_structure", context do
    assert(Service.StoreIndex.event_structure(%{
        domain: "store_index",
        entity_id: "uuid-v4",
        event_id: "uuid-v1-1-0-0",
        kv: "dev_events/uuid-v1-0-0",
        meta: %{"stores" =>
                %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                  3 => "d3bc808a-6078-454b-a606-4538d50fc978"}},
        realm: "nike",
        type: "replace",
      }) ==
      {"replace", %{
          ordered_id: "1-v1-uuid-0-0",
          domain: "store_index",
          entity_id: "uuid-v4",
          data: %{"stores" =>
                %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                  3 => "d3bc808a-6078-454b-a606-4538d50fc978"}}
          }
      }
    )
  end

  test "event when accumulator is empty", context do
    assert(Service.StoreIndex.store_index_reducer_recursive([context[:replace_event]], %{model: %{}, new_events: []})==
      context[:state_after_replace])
  end

  test "handle replace event with previous state", context do
    assert(Service.StoreIndex.call([%Event{
      domain: "store_index",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-2-0-0",
      kv: "dev_events/uuid-v1-0-0",
      meta: %{"stores" =>
              %{1 => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
                3 => "d3bc808a-6078-454b-a606-4538d50fc978",
                4 => "11dec905-a28c-46c9-8572-f68dc6975c91"}
              },
      realm: "nike",
      type: "replace",
    }], context[:state_after_replace]) == context[:state_after_replace2])
  end

  test "is idempotent", context do
    assert(Service.StoreIndex.store_index_reducer_recursive(
        [context[:replace_event], context[:replace_event]],
        %State{model: %{}, new_events: []}
      ) == context[:state_after_replace])
  end
end

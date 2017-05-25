defmodule InitStoreTest do
  use ExUnit.Case

  alias DB.Event
  alias Reducer.State

  test "the truth" do
    assert 1 + 1 == 2
  end

  setup_all _context do
    {:ok, [
      add_event: { "add", %{
        ordered_id: "1-v1-uuid-0-0",
        domain: "store",
        entity_id: "uuid-v4",
        data: %{
          "display_name" => "Store 1",
          "store_number" => 1,
          "district" => "OC",
          "district_id" => 42,
          "territory" => "Southeast",
          "concept" => "NFS",
          "subconcept" => "Clearance"
        }}
      },
      delete_event: {"delete", %{
        ordered_id: "2-v1-uuid-0-0",
        domain: "store",
        entity_id: "uuid-v4",
        data: %{}}
      },
      state_after_add:
        %State{model:
          %{"last_played" => "1-v1-uuid-0-0",
            "name" => "Store 1",
            "number" => 1,
            "district" => "OC",
            "district_id" => 42,
            "territory" => "Southeast",
            "concept" => "NFS",
            "subconcept" => "Clearance",
            "active" => :true},
          new_events: []},

      state_after_delete:
        %State{model:
          %{"last_played" => "2-v1-uuid-0-0",
            "name" => "Store 1",
            "number" => 1,
            "district" => "OC",
            "district_id" => 42,
            "territory" => "Southeast",
            "concept" => "NFS",
            "subconcept" => "Clearance",
            "active" => :false},
          new_events: []}
    ]}
  end

  def strip(event)do
     Map.put(event, :event_id, "")
  end

  test "validate function" do
    assert(Service.Store.validate([%Event{
      domain: "store",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-1-0-0",
      kv: "dev_events/uuid-v1",
      meta:
        %{"display_name" => "Store 1",
          "store_number" => 1,
          "district" => "OC",
          "district_id" => 42,
          "territory" => "Southeast",
          "concept" => "NFS",
          "subconcept" => "Clearance"},
      realm: "nike",
      type: "add",
    },%Event{
      domain: "store",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-1-0-0",
      kv: "dev_events/uuid-v1",
      meta:
        %{"display_name" => "Store 1",
          "store_number" => 1,
          "district" => "OC",
          "district_id" => 42,
          "territory" => "Southeast",
          "concept" => "NFS",
          "subconcept" => "Clearance"},
      realm: "nike",
      type: "add",
    }])==
      [{"add", %{
        ordered_id: "1-v1-uuid-0-0",
        domain: "store",
        entity_id: "uuid-v4",
        data:
          %{"display_name" => "Store 1",
            "store_number" => 1,
            "district" => "OC",
            "district_id" => 42,
            "territory" => "Southeast",
            "concept" => "NFS",
            "subconcept" => "Clearance"}
        }}
      ])
  end



  test "event_structure", context do
    assert(Service.Store.event_structure(%Event{
      domain: "store",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-1-0-0",
      kv: "dev_events/uuid-v1",
      meta:
        %{"display_name" => "Store 1",
          "store_number" => 1,
          "district" => "OC",
          "district_id" => 42,
          "territory" => "Southeast",
          "concept" => "NFS",
          "subconcept" => "Clearance"},
      realm: "nike",
      type: "add",
    }) == context[:add_event])
  end

  test "event when accumulator is empty", context do
    assert(Service.Store.store_reducer_recursive([context[:add_event]], %State{model: %{}, new_events: []})==
      context[:state_after_add])
  end

  test "delete after add", context do
    assert(Service.Store.call([%Event{
      domain: "store",
      entity_id: "uuid-v4",
      event_id: "uuid-v1-2-0-0",
      kv: "dev_events/uuid-v1",
      meta: %{},
      realm: "nike",
      type: "delete"
    }], context[:state_after_add])==context[:state_after_delete])
  end

  test "is idempotent", context do
    assert(Service.Store.store_reducer_recursive([context[:add_event], context[:add_event]],
      %State{model: %{}, new_events: []}) == context[:state_after_add])
  end
end

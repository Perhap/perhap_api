defmodule ServiceChallengeTest do
  use ExUnit.Case
  doctest Service.Challenge

  setup_all _context do
    {:ok, [
      start_event: {:start, %{
        ordered_id: "11e7-25ed-9d16b16c-93ae-92361f002671",
        timestamp: 1492712720633,
        domain: "challenges",
        entity_id: "uuid-v4",
        data: %{
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "timestamp" => "1492712720633",
          "store_id" => 93242,
          "users" => ["338897", "338998", "338904"]}
        }
      },
      stop_event: {:stop, %{
        ordered_id: "11e7-25ee-9d16b16c-93ae-92361f002671",
        timestamp: 1492712820633,
        domain: "challenges",
        entity_id: "uuid-v4",
        data: %{
          "timestamp" => "1492712820633",
          "users" => ["338897", "338998", "338904"]}
        }
      },
      actual_units_event: {:actual_units, %{
        ordered_id: "11e7-25ef-9d16b16c-93ae-92361f002671",
        timestamp: 1492712820833,
        domain: "challenges",
        entity_id: "uuid-v4",
        data: %{
          "timestamp" => "1492712820833",
          "units" => 15,
          "users" => ["338897", "338998", "338904"]}
        }
      },
      edit_event: {:edit, %{
        ordered_id: "11e7-25ff-9d16b16c-93ae-92361f002671",
        timestamp: 1492712820833,
        domain: "challenges",
        entity_id: "uuid-v4",
        data: %{
          "mins" => 2,
          "units" => 45,
          "users" => ["338897", "338998", "338904"]}
        }
      },
      delete_event: {:delete, %{
        ordered_id: "11e7-25ff-9d17b16c-93ae-92361f002671",
        timestamp: 1492712820833,
        domain: "challenges",
        entity_id: "uuid-v4",
        data: %{
          "users" => ["338897", "338998", "338904"]}
        }
      },
      stats_complete_event: %DB.Event{
        domain: "transformer",
        entity_id: "uuid-v4",
        meta: %{
            "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
        },
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"},
      stats_complete_event_partial: %DB.Event{
        domain: "transformer",
        entity_id: "uuid-v4",
        meta: %{
            "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "running"},
        },
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"},
      stats_edit_event: %DB.Event{
        domain: "transformer",
        entity_id: "uuid-v4",
        meta: %{
            "users" => %{
              "338897" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
              "338998" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
              "338904" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
            },
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"},
      stats_delete_event: %DB.Event{
        domain: "transformer",
        entity_id: "uuid-v4",
        meta: %{
            "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "deleted"},
          "338998" => %{"start_time" => 1492712720633, "status" => "deleted"},
          "338904" => %{"start_time" => 1492712720633, "status" => "deleted"},
          },
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"},

      state_after_start: %{
        "last_played" => "11e7-25ed-9d16b16c-93ae-92361f002671",
        "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "running"},
          "338904" => %{"start_time" => 1492712720633, "status" => "running"},
          "338998" => %{"start_time" => 1492712720633, "status" => "running"}
          },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "domain" => "challenges",
        "entity_id" => "uuid-v4",
        "store_id" => 93242},
      state_after_stop: %{
        "last_played" => "11e7-25ee-9d16b16c-93ae-92361f002671",
          "users" => %{
        "338897" => %{"start_time" => 1492712720633, "status" => "stopped", "active_seconds" => 100.0,},
        "338904" => %{"start_time" => 1492712720633, "status" => "stopped", "active_seconds" => 100.0,},
        "338998" => %{"start_time" => 1492712720633, "status" => "stopped", "active_seconds" => 100.0,},
      },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "domain" => "challenges",
        "entity_id" => "uuid-v4",
        "store_id" => 93242},
      state_after_units: %{
        "last_played" => "11e7-25ef-9d16b16c-93ae-92361f002671",
        "entity_id" => "uuid-v4",
        "domain" => "challenges",
        "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
      },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "store_id" => 93242,
      },
      state_after_unfinished: %{
        "last_played" => "11e7-25ef-9d16b16c-93ae-92361f002671",
        "entity_id" => "uuid-v4",
        "domain" => "challenges",
        "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "running"},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
      },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "store_id" => 93242,
      },
      state_after_edit: %{
        "last_played" => "11e7-25ff-9d16b16c-93ae-92361f002671",
        "entity_id" => "uuid-v4",
        "domain" => "challenges",
        "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
          "338904" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
          "338998" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
      },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "store_id" => 93242,
      },
      state_after_delete: %{
        "last_played" => "11e7-25ff-9d17b16c-93ae-92361f002671",
        "entity_id" => "uuid-v4",
        "domain" => "challenges",
        "users" => %{
          "338897" => %{"start_time" => 1492712720633, "status" => "deleted"},
          "338904" => %{"start_time" => 1492712720633, "status" => "deleted"},
          "338998" => %{"start_time" => 1492712720633, "status" => "deleted"},
      },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "store_id" => 93242,
      }
    ]}
  end

  def strip(event)do
     Map.put(event, :event_id, "")
  end

  def uuid_stripper({state, events}) do
    {state, Enum.map(events, fn(event) -> strip(event) end)}
  end

  test "validate function" do
    assert(Service.Challenge.validate([%DB.Event{
      domain: "challenges",
      entity_id: "uuid-v4",
      event_id: "9d16b16c-26ed-11e7-93ae-92361f002671",
      kv: "dev_events/uuid-v1",
      meta: %{
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "timestamp" => "1492712720633",
        "store_id" => 93242,
        "users" => ["338897", "338998", "338904"]},
      realm: "nike",
      type: "sta",
    },%DB.Event{
      domain: "challenges",
      entity_id: "uuid-v4",
      event_id: "9d16b16c-26ed-11e7-93ae-92361f002671",
      kv: "dev_events/uuid-v1",
      meta: %{
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "timestamp" => "1492712720633",
        "store_id" => 93242,
        "users" => ["338897", "338998", "338904"]},
      realm: "nike",
      type: "start",
    }])==
      [
      {:start, %{
        ordered_id: "11e7-26ed-9d16b16c-93ae-92361f002671",
        timestamp: 1492712720633,
        domain: "challenges",
        entity_id: "uuid-v4",
        data: %{
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "timestamp" => "1492712720633",
          "store_id" => 93242,
          "users" => ["338897", "338998", "338904"]}
        }
      }])
  end



  test "event_structure", context do
    assert(Service.Challenge.event_structure(%DB.Event{
      domain: "challenges",
      entity_id: "uuid-v4",
      event_id: "9d16b16c-25ed-11e7-93ae-92361f002671",
      kv: "dev_events/uuid-v1",
      meta: %{
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "timestamp" => "1492712720633",
        "store_id" => 93242,
        "users" => ["338897", "338998", "338904"]},
      realm: "nike",
      type: "start",
    }) == context[:start_event])
  end

  test "event when accumulator is empty", context do
    assert(Service.Challenge.challenge_reducer_recursive([context[:start_event]], {%{}, []})==
      {context[:state_after_start], []})
  end

  test "stop when running", context do
    assert(Service.Challenge.challenge_reducer_recursive([context[:stop_event]],
    {context[:state_after_start], []})== {context[:state_after_stop], []})
  end


  test "uuid stripper" do
    assert(uuid_stripper({%{"users" => %{"338897" => %{"active_seconds" => 120, "actual_units" => 15.0,
    "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
    "338904" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8,
    "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
    "338998" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8,
    "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0}},
    "challenge_benchmark" => 250, "challenge_type" => "equipment", "domain" => "challenges",
    "entity_id" => "uuid-v4", "last_played" => "11e7-25ff-9d16b16c-93ae-92361f002671", "store_id" => 93242},
    [%{domain: "transformer", entity_id: "uuid-v4", meta: %{"users" => %{"338897" => %{"active_seconds" => 120,
    "actual_units" => 15.0, "percentage" => 1.8, "start_time" => 1492712720633,
    "status" => "editted", "uph" => 450.0}, "338904" => %{"active_seconds" => 120,
    "actual_units" => 15.0, "percentage" => 1.8,
    "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
    "338998" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8,
    "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0}},
    "challenge_benchmark" => 250, "challenge_type" => "equipment", "store_id" => 93242},
    realm: "nike", type: "pre_challenge", event_id: '62c02cfa-3669-11e7-a118-2bb80000010f'}]})
    ==
    {%{"users" => %{"338897" => %{"active_seconds" => 120, "actual_units" => 15.0,
    "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted",
    "uph" => 450.0}, "338904" => %{"active_seconds" => 120, "actual_units" => 15.0,
    "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted",
    "uph" => 450.0}, "338998" => %{"active_seconds" => 120, "actual_units" => 15.0,
    "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted",
    "uph" => 450.0}}, "challenge_benchmark" => 250, "challenge_type" => "equipment",
    "domain" => "challenges", "entity_id" => "uuid-v4", "last_played" => "11e7-25ff-9d16b16c-93ae-92361f002671",
    "store_id" => 93242}, [%{domain: "transformer", entity_id: "uuid-v4",
    meta: %{"users" => %{"338897" => %{"active_seconds" => 120, "actual_units" => 15.0,
    "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted",
    "uph" => 450.0}, "338904" => %{"active_seconds" => 120, "actual_units" => 15.0,
    "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
    "338998" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8,
    "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0}},
    "challenge_benchmark" => 250, "challenge_type" => "equipment", "store_id" => 93242},
    realm: "nike", type: "pre_challenge", event_id: ""}]}

      )
  end

  test "start after stop", context do
    assert(Service.Challenge.challenge_reducer_recursive([{:start, %{
      event_id: "9d16b16c-25ef-11e7-93ae-92361f002671",
      ordered_id: "11e7-25ef-9d16b16c-93ae-92361f002671",
      timestamp: 1492712920633,
      domain: "challenges",
      entity_id: "uuid-v4",
      type: "start",
      data: %{
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "timestamp" => "1492712920633",
        "store_id" => 93242,
        "users" => ["338897", "338998", "338904"]}

    }}], {context[:state_after_stop], []})==
      {%{
        "last_played" => "11e7-25ef-9d16b16c-93ae-92361f002671",
        "users" => %{
        "338897" => %{"start_time" => 1492712920633, "status" => "running", "active_seconds" => 100.0,},
        "338904" => %{"start_time" => 1492712920633, "status" => "running", "active_seconds" => 100.0,},
        "338998" => %{"start_time" => 1492712920633, "status" => "running", "active_seconds" => 100.0,},
      },
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "domain" => "challenges",
        "entity_id" => "uuid-v4",
        "store_id" => 93242}, []})
  end
  test "list of events", context do
    assert(uuid_stripper(Service.Challenge.challenge_reducer_recursive([context[:start_event],
    context[:stop_event], context[:actual_units_event]], {%{}, []})) ==
      {context[:state_after_units], [context[:stats_complete_event]]})
  end

  test "list of events unfinished", context do
    assert(uuid_stripper(Service.Challenge.challenge_reducer_recursive([context[:start_event],
    {:stop, %{
      ordered_id: "11e7-25ee-9d16b16c-93ae-92361f002671",
      timestamp: 1492712820633,
      domain: "challenges",
      entity_id: "uuid-v4",
      data: %{
        "timestamp" => "1492712820633",
        "users" => ["338897", "338998"]}
      }
    },
    context[:actual_units_event]
    ], {%{}, []})) ==
      {context[:state_after_unfinished], [context[:stats_complete_event_partial]]})
  end

  test "edit", context do
    assert(uuid_stripper(Service.Challenge.challenge_reducer_recursive([context[:edit_event]],
    {context[:state_after_units], []}
    )) ==
      {context[:state_after_edit], [context[:stats_edit_event]]})
  end

  test "delete", context do
    assert(uuid_stripper(Service.Challenge.challenge_reducer_recursive([context[:delete_event]],
    {context[:state_after_units], []}
    )) ==
      {context[:state_after_delete], [context[:stats_delete_event]]})
  end

  test "incomplete delete", context do
    assert(uuid_stripper(Service.Challenge.challenge_reducer_recursive([context[:delete_event]],
    {context[:state_after_stop], []}
    )) ==
      {context[:state_after_delete], [context[:stats_delete_event]]})
  end

  test "is idempotent", context do
    assert(Service.Challenge.challenge_reducer_recursive([context[:start_event],
    context[:start_event]], {%{}, []})== {context[:state_after_start], []})
  end

  # test "call", context do
  #   assert(Service.Challenge.call())
  # end

end

defmodule Service.StatsTest do
  use ExUnit.Case
  doctest Service.Stats

  alias DB.Event
  alias Reducer.State

  setup_all _context do
    {:ok, [
      unformated_complete: %Event{
        domain: "stats",
        entity_id: "uuid-v4",
        meta: %{
          "users" =>
            %{"338897" => %{"start_time" => 1495279607000, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
              "338904" => %{"start_time" => 1495279607000, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
              "338998" => %{"start_time" => 1495279607000, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72}},
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "challenge_id" => "uuid-v4-challenge-complete",
          "store_id" => 93242},
        event_id: "fb2eb18c-3b3c-11e7-a919-92ebcb67fe33",
        realm: "nike",
        type: "pre_challenge"},
    unformated_pre_actuals: %Event{
      domain: "stats",
      entity_id: "uuid-v4",
      meta: %{
        "Metrics" => "05/10/2017",
        "Metrics2" => "Actual Receipts",
        "C5_Store" => 93242,
        "Count"=> 1968},
      event_id: "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33",
      realm: "nike",
      type: "actuals"},
    stats_complete_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "users" =>
          %{"338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
            "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
            "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72}},
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "challenge_id" => "uuid-v4-challenge-complete",
        "store_id" => 93242},
      event_id: "fb2eb18c-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb18c-a919-92ebcb67fe33",
      realm: "nike",
      type: "pre_challenge"},
    stats_complete_event_partial: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "users" =>
          %{"338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
        "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
        "338904" => %{"start_time" => 1492712720633, "status" => "running"}},
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "challenge_id" => "uuid-v4-challenge-partial",
        "store_id" => 93242},
      event_id: "fb2eb3f8-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb3f8-a919-92ebcb67fe33",
      realm: "nike",
      type: "pre_challenge"},
    stats_edit_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "users" =>
          %{
        "338897" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
        "338998" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
        "338904" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8}},
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "challenge_id" => "uuid-v4-challenge-edit",
        "store_id" => 93242},
      event_id: "fb2eb574-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb574-a919-92ebcb67fe33",
      realm: "nike",
      type: "pre_challenge"},
    stats_delete_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "users" =>
        %{
        "338897" => %{"start_time" => 1492712720633, "status" => "deleted"},
        "338998" => %{"start_time" => 1492712720633, "status" => "deleted"},
        "338904" => %{"start_time" => 1492712720633, "status" => "deleted"}},
        "challenge_benchmark" => 250,
        "challenge_type" => "equipment",
        "challenge_id" => "uuid-v4-challenge-delete",
        "store_id" => 93242},
      event_id: "fb2eb650-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb650-a919-92ebcb67fe33",
      realm: "nike",
      type: "pre_challenge"},
    stats_bin_audit_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "STORE" => 51,
        "DATE" => "05/09/2017",
        "NO_OF_AUDITS_PERFORMED" => 1,
        "PASSED_BIN_COUNT" => 16,
        "BIN_COUNT_TOTAL" => 20,
        "BIN_PERCENTAGE" => 80.0,
        "_BATCH_ID_" => 7,
        "_BATCH_LAST_RUN_" => "2017-03-13T18:10:26",
        "Store Name" => "Airport",
        "dimension" => "Nike Store",
        "territory" => "Inline",
        "district" => "NS01",
        "store_id" => 93242},
      event_id: "fb2eb722-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb722-a919-92ebcb67fe33",
      realm: "nike",
      type: "bin_audit"},
    stats_pre_actual_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "timestamp" => 1493769600000,
        "Metrics" => "05/10/2017",
        "Metrics2" => "Actual Receipts",
        "C5_Store" => 93242,
        "Count"=> 1968},
      event_id: "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb7f4-a919-92ebcb67fe33",
      realm: "nike",
      type: "actuals"},
    stats_refill_actual_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "timestamp" => 1493769600000,
        "Metrics" => "05/14/2017",
        "Metrics2" => "Actual Units Sold",
        "C5_Store" => 93242,
        "Count"=> 1968},
      event_id: "fb2ebbdc-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2ebbdc-a919-92ebcb67fe33",
      realm: "nike",
      type: "actuals"},
    state_after_complete: %{
      "pre" => %{
        "pre_meta" => %{
          "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
          "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
          "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}
          },
        "pre_percentage" => 0.7200000000000001,
        "pre_score" => 0,
        "pre_units" => 15.0,
        }},
      state_after_complete_and_actuals: %{
        "pre" => %{
          "pre_meta" => %{
            "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}
            },
          "pre_percentage" => 0.7200000000000001,
          "pre_score" => 0,
          "pre_units" => 15.0,
          "actual_units" => 1968,
          "accuracy_score" => 0,
          "accuracy_percentage" => 0.007621951219512195,
          "actuals_meta" => %{"fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33" => 1968}
          }},
      state_after_bin: %{
        "pre" => %{
          "pre_meta" => %{
            "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}
            },
          "pre_percentage" => 0.7200000000000001,
          "pre_score" => 0,
          "pre_units" => 15.0,
          },
        "bin_audit" => %{
          "bin_score" => 5,
          "bin_percentage" => 80.0,
        }
          },
    state_after_edit: %{
      "pre" => %{
        "pre_score" => 15,
        "pre_meta" => %{
          "uuid-v4-challenge-edit-338897" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
          "uuid-v4-challenge-edit-338904" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
          "uuid-v4-challenge-edit-338998" => %{"active_seconds" => 120, "actual_units" => 15.0, "percentage" => 1.8, "start_time" => 1492712720633, "status" => "editted", "uph" => 450.0},
          "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
          "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
          "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}},
        "pre_percentage" => 1.26,
        "pre_units" => 60.0}},
    state_after_edit_refill: %{
      "pre" => %{
        "pre_meta" => %{
          "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
          "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
          "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}
          },
        "pre_percentage" => 0.7200000000000001,
        "pre_score" => 0,
        "pre_units" => 15.0},
      "refill" => %{
        "refill_meta" => %{
          "uuid-v4-challenge-edit-338897" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
          "uuid-v4-challenge-edit-338904" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8},
          "uuid-v4-challenge-edit-338998" => %{"start_time" => 1492712720633, "status" => "editted", "active_seconds" => 120, "actual_units" => 15.0, "uph" => 450.0, "percentage" => 1.8}
          },
        "refill_percentage" => 1.8,
        "refill_score" => 15,
        "refill_units" => 45.0}

      },
      state_with_actual_units: %{
        "pre" => %{
          "pre_meta" => %{
            "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}
            },
          "pre_percentage" => 0.7200000000000001,
          "pre_score" => 0,
          "pre_units" => 15.0,
          "actual_units" => 45.0},

        },
        state_after_complete_with_units: %{
          "pre" => %{
            "pre_meta" => %{
              "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
              "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0},
              "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed", "uph" => 180.0}
              },
            "pre_percentage" => 0.7200000000000001,
            "pre_score" => 0,
            "pre_units" => 15.0,
            "actual_units" => 45.0,
            "accuracy_score" => 0,
            "accuracy_percentage" => 0.3333333333333333

            },


          },

          event_from_perhap:   {:pre_challenge, %{domain: "stats", entity_id: "f11f119c-fc2e-4638-a3d5-2c36337c971b", event_id: "4a24fd18-4237-11e7-9382-17570000028a", kv: "dev_events/4a24fd18-4237-11e7-9382-17570000028a", kv_time: "",
            data: %{"challenge_benchmark" => 250, "challenge_id" => "d50c1de9-c34a-4bcc-ae94-85e704e727f1",
            "challenge_type" => "equipment", "store_id" => 93242,
            "users" => %{"338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0,
            "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed",
            "uph" => 180.0}, "338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0,
             "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed",
             "uph" => 180.0}, "338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0,
              "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed",
               "uph" => 180.0}}}, realm: "nike", remote_ip: "127.0.0.1", type: "pre_challenge"}},
       out_of_season_event: %Event{domain: "stats", entity_id: "f11f119c-fc2e-4638-a3d5-2c36337c971b", event_id: "4a24fd18-4237-11e7-9382-17570000028a", kv: "dev_events/4a24fd18-4237-11e7-9382-17570000028a", kv_time: "",
           meta: %{"challenge_benchmark" => 250, "challenge_id" => "d50c1de9-c34a-4bcc-ae94-85e704e727f1",
           "challenge_type" => "equipment", "store_id" => 93242,
           "users" => %{"338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0,
           "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed",
           "uph" => 180.0}, "338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0,
            "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed",
            "uph" => 180.0}, "338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0,
             "percentage" => 0.72, "start_time" => 1492712720633, "status" => "completed",
              "uph" => 180.0}}}, realm: "nike", remote_ip: "127.0.0.1", type: "pre_challenge"}




        ]}
    end

test "pre_meta", context do
  assert(Service.Stats.add_meta(context[:stats_complete_event], %{
    "uuid-v4-challenge-delete-338891" => %{"start_time" => 1492712720633, "status" => "deleted"},
    "uuid-v4-challenge-delete-338992" => %{"start_time" => 1492712720633, "status" => "deleted"},
    "uuid-v4-challenge-delete-338903" => %{"start_time" => 1492712720633, "status" => "deleted"}}
    )==
      %{"uuid-v4-challenge-delete-338891" => %{"start_time" => 1492712720633, "status" => "deleted"},
    "uuid-v4-challenge-delete-338992" => %{"start_time" => 1492712720633, "status" => "deleted"},
    "uuid-v4-challenge-delete-338903" => %{"start_time" => 1492712720633, "status" => "deleted"},
    "uuid-v4-challenge-complete-338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
    "uuid-v4-challenge-complete-338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
    "uuid-v4-challenge-complete-338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72}
    })
end

  test "percentage average" do
    assert(Service.Stats.average(%{"uuid-v4-challenge-delete-338891" => %{"start_time" => 1492712720633, "status" => "deleted"},
  "uuid-v4-challenge-delete-338992" => %{"start_time" => 1492712720633, "status" => "deleted"},
  "uuid-v4-challenge-delete-338903" => %{"start_time" => 1492712720633, "status" => "deleted"},
  "uuid-v4-challenge-complete-338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
  "uuid-v4-challenge-complete-338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
  "uuid-v4-challenge-complete-338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72}
  }, "percentage")== 0.7200000000000001)
  end

  test "points 89" do
    assert(Service.Stats.percentage_score(0.89) == 0)
  end

  test "points 90" do
    assert(Service.Stats.percentage_score(0.9) == 5)
  end

  test "points 100" do
    assert(Service.Stats.percentage_score(1.0) == 10)
  end

  test "points 120" do
    assert(Service.Stats.percentage_score(1.2) == 15)
  end

  test "pre_challenge", context do
    assert(Service.Stats.pre_challenge({:pre_challenge, context[:stats_complete_event]}, {%{}, []})=={context[:state_after_complete], []})
  end

  test "pre challenge after edit", context do
    assert(Service.Stats.pre_challenge({:pre_challenge, context[:stats_edit_event]}, {context[:state_after_complete], []})== {context[:state_after_edit], []})
  end

  test "refill challenge after edit", context do
    assert(Service.Stats.refill_challenge({:refill_challenge, context[:stats_edit_event]}, {context[:state_after_complete], []})== {context[:state_after_edit_refill], []})
  end

  test "bin_audit", context do
    assert(Service.Stats.bin_audit({:bin_audit, context[:stats_bin_audit_event]}, {context[:state_after_complete], []}) ==
      {context[:state_after_bin], []})
  end

  test "pre_actual with no begining state", context do
    assert(Service.Stats.actuals({:actuals, context[:stats_pre_actual_event]}, {%{}, []}) == {%{"pre" => %{"actual_units" => 1968, "actuals_meta" => %{"fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33" => 1968}}}, []})
  end

  test "pre_actual with exisiting begining state", context do
    assert(Service.Stats.actuals({:actuals, context[:stats_pre_actual_event]}, {context[:state_after_complete], []}) == {context[:state_after_complete_and_actuals], []})
  end

  test "refill_actual with no begining state", context do
    assert(Service.Stats.actuals({:actuals, context[:stats_refill_actual_event]}, {%{}, []}) == {%{"refill" => %{"actual_units" => 1968, "actuals_meta" => %{"fb2ebbdc-3b3c-11e7-a919-92ebcb67fe33" => 1968}}}, []})
  end

  test "date" do
    assert(Service.Stats.date("5/30/2017") == 1496160000000)
  end

  test "get_timestamp", context do
    assert(Service.Stats.get_timestamp({:pre_challenge, context[:stats_delete_event]})==1492712720633)
  end

  test "get timestamp bin_audit", context do
    assert(Service.Stats.get_timestamp({:bin_audit, context[:stats_bin_audit_event]}) == 1494345600000)
  end

  test "get timestamp actual", context do
    assert(Service.Stats.get_timestamp({:actuals, context[:stats_pre_actual_event]}) == 1494432000000)
  end

  test "pre challenge with exisiting units", context do
    assert(Service.Stats.pre_challenge({:pre_challenge, context[:stats_complete_event]}, {context[:state_with_actual_units], []}) == {context[:state_after_complete_with_units], []})
  end

  test "find_period" do
    assert(Service.Stats.find_period(1497855700000, Season1periods)== "season1week3")
  end

  test "get_period_model" do
    assert(Service.Stats.get_period_model("season1week5",
    %{
      "store_id" => 567,
      "season" => 1,
      "stats" => %{
        "season1week4" => %{"pre" => "somedata"},
        "season1week5" => %{"pre" => "somedifferentdata"}
      }
      }) == %{"pre" => "somedifferentdata"})
  end

  test "get_period_model no match" do
    assert(Service.Stats.get_period_model("season1week2",
    %{
      "store_id" => 567,
      "season" => 1,
      "stats" => %{
        "season1week4" => %{"pre" => "somedata"},
        "season1week5" => %{"pre" => "somedifferentdata"}
      }
      }) == %{})
  end

  test "call", context do
    assert(Service.Stats.call([context[:unformated_complete], context[:unformated_pre_actuals]], %State{})
    == %State{model: %{
      "last_played" => "11e7-3b3c-fb2eb7f4-a919-92ebcb67fe33",
      "season" => Season1,
      "stats" => %{
        "season1preseason" => %{
          "pre" => %{
            "accuracy_percentage" => 0.007621951219512195,
            "accuracy_score" => 0, "actual_units" => 1968,
            "actuals_meta" => %{
              "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33" => 1968},
            "pre_meta" => %{
              "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
              "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
              "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0}},
            "pre_percentage" => 0.7200000000000001,
            "pre_score" => 0,
            "pre_units" => 15.0
            }
          }
        }
      }, new_events: []})
  end


test " get timestamp and find period", context do
  assert(Service.Stats.get_timestamp(context[:event_from_perhap])
  |> Service.Stats.find_period(Application.get_env(:reducers, :current_periods))== "out_of_season")
end

test "out of season event", context do
  assert(Service.Stats.call([context[:unformated_complete], context[:unformated_pre_actuals], context[:out_of_season_event]], %State{model: %{}, new_events: []})== %State{model: %{
    "last_played" => "11e7-3b3c-fb2eb7f4-a919-92ebcb67fe33",
    "season" => Season1,
    "stats" => %{
      "season1preseason" => %{
        "pre" => %{
          "accuracy_percentage" => 0.007621951219512195,
          "accuracy_score" => 0, "actual_units" => 1968,
          "actuals_meta" => %{
            "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33" => 1968},
          "pre_meta" => %{
            "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0}},
          "pre_percentage" => 0.7200000000000001,
          "pre_score" => 0,
          "pre_units" => 15.0
          }
        }
      }
    }, new_events: []})
end

test "get_period_model out of season" do
  assert(Service.Stats.get_period_model("out_of_season", %{})== :out_of_season)
end


test " get new model", context do
  assert(Service.Stats.get_new_model({:pre_challenge, context[:out_of_season]}, {:out_of_season, []}, %{}, "out_of_season") == {%{}, []})
end

test "out of season with begining state", context do
  assert(Service.Stats.call([context[:out_of_season_event]], %State{model: %{
    "last_played" => "11e7-3b3c-fb2eb7f4-a919-92ebcb67fe33",
    "season" => Season1,
    "stats" => %{
      "season1preseason" => %{
        "pre" => %{
          "accuracy_percentage" => 0.007621951219512195,
          "accuracy_score" => 0, "actual_units" => 1968,
          "actuals_meta" => %{
            "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33" => 1968},
          "pre_meta" => %{
            "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
            "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0}},
          "pre_percentage" => 0.7200000000000001,
          "pre_score" => 0,
          "pre_units" => 15.0
          }
        }
      }
    }, new_events: []})== %State{model: %{
      "last_played" => "11e7-3b3c-fb2eb7f4-a919-92ebcb67fe33",
      "season" => Season1,
      "stats" => %{
        "season1preseason" => %{
          "pre" => %{
            "accuracy_percentage" => 0.007621951219512195,
            "accuracy_score" => 0, "actual_units" => 1968,
            "actuals_meta" => %{
              "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33" => 1968},
            "pre_meta" => %{
              "uuid-v4-challenge-complete-338897" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
              "uuid-v4-challenge-complete-338904" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0},
              "uuid-v4-challenge-complete-338998" => %{"active_seconds" => 100.0, "actual_units" => 5.0, "percentage" => 0.72, "start_time" => 1495279607000, "status" => "completed", "uph" => 180.0}},
            "pre_percentage" => 0.7200000000000001,
            "pre_score" => 0,
            "pre_units" => 15.0
            }
          }
        }
      }, new_events: []})
end

# test "actaul event from perhap" do
#   assert(Service.Stats.call( [%DB.Event{domain: "stats", entity_id: "53f97f3c-8174-42e6-a2e8-f8cd153715fb", event_id: "86008180-46de-11e7-b67d-abb60000017a", kv: <<112, 114, 111, 100, 31, 101, 118, 101, 110, 116, 115, 47, 56, 54, 48, 48, 56, 49, 56, 48, 45, 52, 54, 100, 101, 45, 49, 49, 101, 55, 45, 98, 54, 55, 100, 45, 97, 98, 98, 54, 48, 48, 48, 48, 48, 49>>, kv_time: "", meta: %{"challenge_benchmark" => 150, "challenge_id" => "c75d01af-57c9-475f-8a21-aa54aec6e031", "challenge_type" => "footwear", "store_id" => 39, "users" => %{"145083" => %{"start_time" => 1496329896784, "status" => "running"}}}, realm: "nike", remote_ip: "127.0.0.1", type: "pre_challenge"}],
#               %Reducer.State{deferred_events: [], model: %{"last_played" => "11e7-46dc-b7c620d2-b9ae-abb40000017f", "season" => "Elixir.Season1", "stats" => %{"season1preseason" => %{"pre" => %{"pre_meta" => %{"222f5d9f-f835-4eae-83f1-10f263b2520f-311241" => %{"active_seconds" => 1895.457, "actual_units" => 77.0, "percentage" => 0.9749627662352667, "start_time" => 1496251037740, "status" => "completed", "uph" => 146.24441493529}, "75a0d82a-a5cc-4eff-9294-340d6e46d670-261536" => %{"active_seconds" => 53409.252, "actual_units" => 42.0, "percentage" => 0.03145522427462567, "start_time" => 1496276525382, "status" => "completed", "uph" => 2.830970184716311}, "b6f30a87-6180-49fc-bc90-078d6986da22-338121" => %{"active_seconds" => 1898.911, "actual_units" => 97.0, "percentage" => 1.2259658298888152, "start_time" => 1496251166125, "status" => "completed", "uph" => 183.89487448332227}}, "pre_percentage" => 0.7441279401329025, "pre_score" => 0, "pre_units" => 216.0}}}}, new_events: []})== %{})
# end

end

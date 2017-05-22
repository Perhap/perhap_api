defmodule Service.StatsTest do
  use ExUnit.Case
  doctest Service.Stats

  alias DB.Event
  alias Reducer.State

  setup_all _context do
    {:ok, [
      unformated_complete: %{
        domain: "stats",
        entity_id: "uuid-v4",
        meta: %{
          "users" =>
            %{"338897" => %{"start_time" => 1495279607000, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
              "338904" => %{"start_time" => 1495279607000, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
              "338998" => %{"start_time" => 1495279607000, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72}},
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "fb2eb18c-3b3c-11e7-a919-92ebcb67fe33",
        realm: "nike",
        challenge_id: "uuid-v4-challenge-complete",
        type: "pre_challenge"},
    unformated_pre_actuals: %{
      domain: "stats",
      entity_id: "uuid-v4",
      meta: %{
        "Metrics" => "2017-05-10",
        "Metrics2" => "Actual Receipts",
        "C5_Store" => 93242,
        "Count"=> 1968},
      event_id: "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge",
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
        "store_id" => 93242},
      event_id: "fb2eb18c-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb18c-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge-complete",
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
        "store_id" => 93242},
      event_id: "fb2eb3f8-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb3f8-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge-partial",
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
        "store_id" => 93242},
      event_id: "fb2eb574-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb574-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge-edit",
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
        "store_id" => 93242},
      event_id: "fb2eb650-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb650-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge-delete",
      type: "pre_challenge"},
    stats_bin_audit_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "STORE" => 51,
        "DATE" => "2017-05-09",
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
      challenge_id: "uuid-v4-challenge",
      type: "bin_audit"},
    stats_pre_actual_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "timestamp" => 1493769600000,
        "Metrics" => "2017-05-10",
        "Metrics2" => "Actual Receipts",
        "C5_Store" => 93242,
        "Count"=> 1968},
      event_id: "fb2eb7f4-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2eb7f4-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge",
      type: "actuals"},
    stats_refill_actual_event: %{
      domain: "stats",
      entity_id: "uuid-v4",
      data: %{
        "timestamp" => 1493769600000,
        "Metrics" => "2017-05-14",
        "Metrics2" => "Actual Units Sold",
        "C5_Store" => 93242,
        "Count"=> 1968},
      event_id: "fb2ebbdc-3b3c-11e7-a919-92ebcb67fe33",
      ordered_id: "11e7-3b3c-fb2ebbdc-a919-92ebcb67fe33",
      realm: "nike",
      challenge_id: "uuid-v4-challenge",
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


          }
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
    assert(Service.Stats.date("2017-5-30") == 1496160000000)
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
    assert(Service.Stats.find_period(1497855700000, Season1periods)== "season1week5")
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
    assert(Service.Stats.call([context[:unformated_complete], context[:unformated_pre_actuals]], %{})
    == %{model: %{
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


end

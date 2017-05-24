defmodule TransformerServiceTest do
  use ExUnit.Case
  doctest TransformerService

  setup_all _context do
    {:ok, [
      stores: %{
        356 => "4d49741d-ad8c-4f1a-8495-f1c28b9896bd",
        357 => "62e36a89-7548-4fe0-8020-f059ce8549c2",
        358 => "74957173-3707-4976-926e-67dca5637625",
        359 => "af85b32f-13f6-409c-b82e-ee2b6a2deee0",
        360 => "d68e938f-c597-4ada-9f7a-5bcad3dbbaaf",
        361 => "8222fa94-8e1f-42a7-b1db-b8ad7b535545",
        362 => "b376f6a9-e141-4b34-b93d-166e634992ca",
        363 => "d9a3bf8c-23f5-46c9-bb6a-2c7ac7b8932f",
        364 => "cad583e8-cd49-4fd4-a86f-115d7110271b",
      },
      stats_complete_event: %{
        domain: "transformer",
        entity_id: "uuid-v4",
        meta: %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"},
      transformed_event: %{
        domain: "stats",
        challenge_id: "uuid-v4",
        entity_id: "8222fa94-8e1f-42a7-b1db-b8ad7b535545",
        meta: %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"}
      ]}
    end

  test "gets uuid from fake api", context do
    assert(TransformerService.get_entity_id(context[:stores], 360)== "d68e938f-c597-4ada-9f7a-5bcad3dbbaaf")
  end

  test "transformer", context do
    assert(TransformerService.transform_event(context[:stats_complete_event])== context[:transformed_event])
  end
end

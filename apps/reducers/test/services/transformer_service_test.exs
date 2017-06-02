defmodule ServiceTransformerTest do
  use ExUnit.Case
  doctest Service.Transformer

  alias DB.Event

  setup_all _context do
    {:ok, [
      stores: %{
        356 => "4d49741d-ad8c-4f1a-8495-f1c28b9896bd",
        357 => "62e36a89-7548-4fe0-8020-f059ce8549c2",
        358 => "74957173-3707-4976-926e-67dca5637625",
        359 => "af85b32f-13f6-409c-b82e-ee2b6a2deee0",
        "360" => "d68e938f-c597-4ada-9f7a-5bcad3dbbaaf",
        361 => "8222fa94-8e1f-42a7-b1db-b8ad7b535545",
        362 => "b376f6a9-e141-4b34-b93d-166e634992ca",
        363 => "d9a3bf8c-23f5-46c9-bb6a-2c7ac7b8932f",
        364 => "cad583e8-cd49-4fd4-a86f-115d7110271b",
      },
      stats_complete_event: %Event{
        domain: "transformer",
        entity_id: "uuid-v4",
        meta: %{
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242,
          "challenge_id" => "uuid-v4-old"},
        event_id: "",
        realm: "nike",
        type: "pre_challenge_transform"},
      transformed_event: %Event{
        domain: "stats",
        entity_id: nil,
        meta: %{
          "challenge_id" => "uuid-v4-old",
          "338897" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338904" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "338998" => %{"start_time" => 1492712720633, "status" => "completed", "active_seconds" => 100.0, "actual_units" => 5.0, "uph" => 180.0, "percentage" => 0.72},
          "challenge_benchmark" => 250,
          "challenge_type" => "equipment",
          "store_id" => 93242},
        event_id: "",
        realm: "nike",
        type: "pre_challenge"},
      store_event: %Event{
        domain: "storeindex",
        entity_id: "100077bd-5b34-41ac-b37b-62adbf86c1a5",
        meta: %{
          "hashes" => "",
          "last_played" => "11e7-4196-9e88fe46-a919-92ebcb67fe33",
          "stores" => %{
            "1" => "90fe1871-b8d2-4a94-baf5-ef7475533f0e",
            "2" => "81bc429d-d055-4002-a64f-59e1af501236",
            "3" => "d3bc808a-6078-454b-a606-4538d50fc978",
            "93242" => "f11f119c-fc2e-4638-a3d5-2c36337c971b"
          }
        },
        event_id: "2e428c72-4251-11e7-a919-92ebcb67fe33",
        realm: "nike",
        type: "replace"}
      ]}
    end


  test "gets uuid from fake api", context do
    assert(Service.Transformer.get_entity_id(context[:stores], 360)== "d68e938f-c597-4ada-9f7a-5bcad3dbbaaf")
  end

  test "transformer", context do
    assert(Service.Transformer.transform_event(context[:stats_complete_event], {"model", []}) == {"model", [context[:transformed_event]]} )
  end
end

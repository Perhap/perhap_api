defmodule ServiceDomoTest do
  use ExUnit.Case
  doctest Service.Domo

  alias DB.Event

  def strip(event)do
     Map.put(event, :event_id, "")
  end

  def uuid_stripper({events, col_heads, type, hash_state}) do
    stripped = Enum.map(events, fn(event) -> strip(event) end)
    {stripped, col_heads, type, hash_state}
  end

  # body = "1,2,3,4\na,b,c,d\nd,c,b,a\nw,x,y,z"
  test "hash file and build event with empty state" do
    state = %{}
    type = "bin_audits"
    body = "STORE,DATE,NO_OF_AUDITS_PERFORMED,PASSED_BIN_COUNT,BIN_COUNT_TOTAL,BIN_PERCENTAGE,_BATCH_ID_,_BATCH_LAST_RUN_\n\"3\",\"12/30/2016\",\"1\",\"20\",\"20\",\"100\",\"1\",\"2017-01-18T22:21:04\"\n\"8\",\"12/30/2016\",\"1\",\"13\",\"20\",\"65\",\"1\",\"2017-01-18T22:21:04\"\n"
    expected = {[
      %Event{domain: "stats", remote_ip: "127.0.0.1", event_id: "", realm: "nike", type: "bin_audits", entity_id: "8", meta: %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "65", "DATE" => "12/30/2016", "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "13", "STORE" => "8", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04"}},
      %Event{domain: "stats", remote_ip: "127.0.0.1", event_id: "", realm: "nike", type: "bin_audits", entity_id: "3", meta: %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "100", "DATE" => "12/30/2016", "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "20", "STORE" => "3", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04"}}
      ],
      "STORE,DATE,NO_OF_AUDITS_PERFORMED,PASSED_BIN_COUNT,BIN_COUNT_TOTAL,BIN_PERCENTAGE,_BATCH_ID_,_BATCH_LAST_RUN_",
      "bin_audits",
      %HashState{
        missing: [],
        hashes: ["F69EE687845AF0BB2EADF790F355C6454BA8C556", "9C9398B1526825551ECA416C24AFFE851E959441"],
        lines: ["\"8\",\"12/30/2016\",\"1\",\"13\",\"20\",\"65\",\"1\",\"2017-01-18T22:21:04\"", "\"3\",\"12/30/2016\",\"1\",\"20\",\"20\",\"100\",\"1\",\"2017-01-18T22:21:04\""]}}
    assert Service.Domo.hash_file(body, state, type) |> uuid_stripper == expected
  end

  test "hash file and build event with non-empty state" do
    state = %{last_played: "1234", hash_state: %HashState{hashes: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                                                   "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                                                   "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                                                          lines: ["w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []}}
    type = "actuals"
    body = "\"Store\",2,3,4\na,b,c,d\nd,c,b,a\nw,x,y,z\nz,y,x,w"
    expected = {[%Event{domain: "stats", entity_id: "z", event_id: "", remote_ip: "127.0.0.1",
               meta: %{"Store" => "z", "2" => "y", "3" => "x", "4" => "w"},
               realm: "nike", type: "actuals"}],
              "\"Store\",2,3,4",
              "actuals",
              %HashState{hashes: ["973534CEA1CB3C8502A5599CCFCBC2A103DC0A21",
                                  "CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                  "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                  "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                        lines: ["z,y,x,w", "w,x,y,z", "d,c,b,a", "a,b,c,d", "w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []}}

    assert Service.Domo.hash_file(body, state, type) |> uuid_stripper == expected
  end

  test "build a meta map" do
    col_heads = "1,2,3,4"
    row = "a,b,c,d"
    assert Service.Domo.build_meta_map(col_heads, row) == %{"1" => "a", "2" => "b", "3" => "c", "4" => "d"}
  end

  test "is_empty? returns given hash state" do
    model = %{last_played: "1234", hash_state: %HashState{hashes: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                                                   "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                                                   "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                                                          lines: ["w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []}}
    expected = %HashState{hashes: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                   "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                   "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                          lines: ["w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []}

    assert Service.Domo.is_empty?(model) == expected
  end

  test "is_empty? returns empty hash state if given empty map" do
    model = %{}
    expected = %HashState{hashes: [], lines: [], missing: []}
    assert Service.Domo.is_empty?(model) == expected
  end

  test "return model and events" do
    last_played = 'bbdfb95c-3fee-11e7-a4cc-c5b7000000f1'
    new_events = [%{domain: "stats", entity_id: "w", event_id: "",
                    meta: %{"1" => "w", "2" => "x", "3" => "y", "4" => "z"},
                    realm: "nike", type: "bin_audits"},
                  %{domain: "stats", entity_id: "d", event_id: "",
                    meta: %{"1" => "d", "2" => "c", "3" => "b", "4" => "a"},
                    realm: "nike", type: "bin_audits"},
                  %{domain: "stats", entity_id: "a", event_id: "",
                    meta: %{"1" => "a", "2" => "b", "3" => "c", "4" => "d"},
                    realm: "nike", type: "bin_audits"}]
    col_heads = "\"Store\",2,3,4"
    type = "bin_audits"
    hash_state = %HashState{hashes: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                     "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                     "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                            lines: ["w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []}

    expected = {%{hash_state: %HashState{hashes: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                                           "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                                           "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                                                  lines: ["w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []},
                          last_played: 'bbdfb95c-3fee-11e7-a4cc-c5b7000000f1'},
                [%{domain: "stats", entity_id: "w", event_id: "",
                    meta: %{"1" => "w", "2" => "x", "3" => "y", "4" => "z"},
                    realm: "nike", type: "bin_audits"},
                %{domain: "stats", entity_id: "d", event_id: "",
                    meta: %{"1" => "d", "2" => "c", "3" => "b", "4" => "a"},
                    realm: "nike", type: "bin_audits"},
                %{domain: "stats", entity_id: "a", event_id: "",
                    meta: %{"1" => "a", "2" => "b", "3" => "c", "4" => "d"},
                    realm: "nike", type: "bin_audits"}]}


    assert Service.Domo.return_model_and_events({new_events, col_heads, type, hash_state}, last_played) == expected
  end



end

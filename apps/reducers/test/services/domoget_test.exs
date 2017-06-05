defmodule ServiceDomoTest do
  use ExUnit.Case
  doctest Service.Domo

  alias DB.Event

  def strip(event)do
     Map.put(event, :event_id, "")
  end

  def uuid_stripper({events, col_heads, type, hash_state, store_ids}) do
    stripped = Enum.map(events, fn(event) -> strip(event) end)
    {stripped, col_heads, type, hash_state, store_ids}
  end

  # body = "1,2,3,4\na,b,c,d\nd,c,b,a\nw,x,y,z"
  test "hash file and build event with empty state" do
    state = %{}
    store_ids = %{
      "93242"=> "517539dc-f3e0-47b0-9f1e-559df39eaeda",
      "3"=> "48b76a2c-ead3-48e9-acf8-2d87adbc17b1"
    }
    type = "bin_audits"
    body = "STORE,DATE,NO_OF_AUDITS_PERFORMED,PASSED_BIN_COUNT,BIN_COUNT_TOTAL,BIN_PERCENTAGE,_BATCH_ID_,_BATCH_LAST_RUN_\n\"3\",\"12/30/2016\",\"1\",\"20\",\"20\",\"100\",\"1\",\"2017-01-18T22:21:04\"\n\"93242\",\"12/30/2016\",\"1\",\"13\",\"20\",\"65\",\"1\",\"2017-01-18T22:21:04\"\n"
    expected = {[
      %DB.Event{domain: "stats", event_id: "", kv: "", kv_time: "", realm: "nike", remote_ip: "127.0.0.1", type: "bin_audits", entity_id: "517539dc-f3e0-47b0-9f1e-559df39eaeda", meta: %{"BIN_COUNT_TOTAL" => "20", "DATE" => "12/30/2016", "NO_OF_AUDITS_PERFORMED" => "1", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "BIN_PERCENTAGE" => "65", "PASSED_BIN_COUNT" => "13", "STORE" => "93242"}},
      %DB.Event{domain: "stats", event_id: "", kv: "", kv_time: "", realm: "nike", remote_ip: "127.0.0.1", type: "bin_audits", entity_id: "48b76a2c-ead3-48e9-acf8-2d87adbc17b1", meta: %{"BIN_COUNT_TOTAL" => "20", "BIN_PERCENTAGE" => "100", "DATE" => "12/30/2016", "NO_OF_AUDITS_PERFORMED" => "1", "PASSED_BIN_COUNT" => "20", "_BATCH_ID_" => "1", "_BATCH_LAST_RUN_" => "2017-01-18T22:21:04", "STORE" => "3"}}], "STORE,DATE,NO_OF_AUDITS_PERFORMED,PASSED_BIN_COUNT,BIN_COUNT_TOTAL,BIN_PERCENTAGE,_BATCH_ID_,_BATCH_LAST_RUN_",
      "bin_audits",
      %HashState{missing: [], hashes: ["2EDBBE95C4BD4C691856ADE5A5863929CA2E8912", "9C9398B1526825551ECA416C24AFFE851E959441"], lines: ["\"93242\",\"12/30/2016\",\"1\",\"13\",\"20\",\"65\",\"1\",\"2017-01-18T22:21:04\"", "\"3\",\"12/30/2016\",\"1\",\"20\",\"20\",\"100\",\"1\",\"2017-01-18T22:21:04\""]},
      %{"3" => "48b76a2c-ead3-48e9-acf8-2d87adbc17b1", "93242" => "517539dc-f3e0-47b0-9f1e-559df39eaeda"}}
    assert Service.Domo.hash_file(body, state, type, store_ids) |> uuid_stripper == expected
  end


  test "hash file and build event with non-empty state" do
      state = %{"last_played" => "1234", "hash_state" => [
        "CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
        "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
        "3DCDA24350A7219C75A34CB4F0079978D4B63E95"
        ],
        }
      type = "actuals"
      store_ids = %{
        "1"=> "517539dc-f3e0-47b0-9f1e-559df39eaeda",
        "3"=> "48b76a2c-ead3-48e9-acf8-2d87adbc17b1"
      }
      body = "STORE,2,3,4\na,b,c,d\nd,c,b,a\nw,x,y,z\nz,y,x,w"
      expected = {[],
                "STORE,2,3,4",
                "actuals",
                %HashState{hashes: ["973534CEA1CB3C8502A5599CCFCBC2A103DC0A21",
                "CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                          lines: ["z,y,x,w", "w,x,y,z", "d,c,b,a", "a,b,c,d"], missing: []},
                          %{"1" => "517539dc-f3e0-47b0-9f1e-559df39eaeda", "3" => "48b76a2c-ead3-48e9-acf8-2d87adbc17b1"}}

      assert Service.Domo.hash_file(body, state, type, store_ids)  == expected
    end

  test "build a meta map" do
    col_heads = "1,2,3,4"
    row = "a,b,c,d"
    assert Service.Domo.build_meta_map(col_heads, row) == %{"1" => "a", "2" => "b", "3" => "c", "4" => "d"}
  end

  test "is_empty? returns given hash state" do
    model = %{"last_played" => "1234", "hash_state"=> ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                                                   "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                                                   "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                                                        }
    expected = %HashState{hashes: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                   "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                   "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
                          lines: [], missing: []}

    assert Service.Domo.is_empty?(model) == expected
  end

  test "is_empty? returns empty hash state if given empty map" do
    model = %{}
    expected = %HashState{hashes: [], lines: [], missing: []}
    assert Service.Domo.is_empty?(model) == expected
  end

  test "return model and events" do
    store_ids = %{
      "93242"=> "517539dc-f3e0-47b0-9f1e-559df39eaeda",
      "3"=> "48b76a2c-ead3-48e9-acf8-2d87adbc17b1"
    }
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
                            lines: [], missing: []}

    expected = {%{hash_state: ["CC22CA3EC5D35ABD75B4C07D1C2894FE8A1EDC29",
                                                           "A144EC353DB30592E97C80BFC6A3A2E617CE65B3",
                                                           "3DCDA24350A7219C75A34CB4F0079978D4B63E95"],
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


    assert Service.Domo.return_model_and_events({new_events, col_heads, type, hash_state, store_ids}, last_played) == expected
  end



end

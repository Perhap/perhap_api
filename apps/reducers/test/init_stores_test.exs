defmodule InitStoreTest do
  use ExUnit.Case
  doctest Mix.Tasks.InitStores

  alias Mix.Tasks.InitStores

  defp ctx do
    %{lastHashes: %{1 => "fakehash1", 2 => "fakehash2"},
      lastEIds: %{1 => "uuidv4-1", 2 => "uuidv4-2"},
      emptyAcc: %{oldMaps: %{}, newHashes: %{}, newEntIds: %{}},
      skipAcc: %{oldMaps: %{28 => %{hash: "fakehash1", entity_id: "uuidv4-1"}},
                 newHashes: %{}, newEntIds: %{}}
     }
  end

  test "makeIdMaps returns list of maps" do
    assert InitStores.makeIdMaps(ctx().lastHashes, ctx().lastEIds) ==
      %{1 => %{hash: "fakehash1", entity_id: "uuidv4-1"},
        2 => %{hash: "fakehash2", entity_id: "uuidv4-2"}}
  end

  test "makeIdMaps handles hash with no eid" do
    assert InitStores.makeIdMaps(ctx().lastHashes, Map.delete(ctx().lastEIds, 2)) ==
      %{1 => %{hash: "fakehash1", entity_id: "uuidv4-1"},
        2 => %{hash: "fakehash2", entity_id: nil}}
  end

  test "makeIdMaps handles eid with no hash" do
    assert InitStores.makeIdMaps(Map.delete(ctx().lastHashes, 1), ctx().lastEIds) ==
      %{1 => %{hash: nil, entity_id: "uuidv4-1"},
        2 => %{hash: "fakehash2", entity_id: "uuidv4-2"}}
  end

  test "parse a basic row" do
    parsed = InitStores.hashParse("335,,Reno,NFS,Factory Store,West,3,Nor Cal")

    assert parsed.storenum == 335
    assert is_nil(parsed.id_storenum)
    assert parsed.name == "Reno"
    assert parsed.concept == "NFS"
    assert parsed.subconcept == "Factory Store"
    assert parsed.terr == "West"
    assert parsed.distnum == 3
    assert parsed.distname == "Nor Cal"
    assert is_bitstring(parsed.hash) && String.length(parsed.hash) == 64
  end

  test "parse an offsite service center" do
    parsed = InitStores.hashParse("298,59,Woodbury SC,NFS,Offsite Service Center,Northeast,20,NY/S Jersey")

    assert parsed.storenum == 298
    assert parsed.id_storenum == 59
    assert parsed.name == "Woodbury SC"
    assert is_bitstring(parsed.hash) && String.length(parsed.hash) == 64
  end

  test "fold from blank" do
    parsed_line =
      InitStores.hashParse("28,,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")

    state = InitStores.diffFold(&IO.inspect/1, parsed_line, ctx().emptyAcc)

    assert state.oldMaps == %{}
    assert state.newHashes[28] == parsed_line.hash
    assert UUID.info!(state.newEntIds[28])[:version] == 4
  end

  test "fold an unchanged event" do
    parsed_line =
      InitStores.hashParse("28,,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
      |> Map.put(:hash, "fakehash1")

    state = InitStores.diffFold(fn x -> x end, parsed_line, ctx().skipAcc)

    assert state.oldMaps == %{}
    assert state.newHashes[28] == "fakehash1"
    assert state.newEntIds[28] == "uuidv4-1"
  end

  test "merged a store to an existing store" do
    parsed_line1 =
      InitStores.hashParse("28,,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
      |> Map.put(:hash, "fakehash1")

    parsed_line2 =
      InitStores.hashParse("88,28,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
      |> Map.put(:hash, "fakehash2")

    state = Enum.reduce([parsed_line1, parsed_line2], ctx().skipAcc,
      fn item, acc -> InitStores.diffFold(&IO.inspect/1, item, acc) end
      )

    assert state.oldMaps == %{}
    assert state.newHashes[28] == "fakehash1"
    assert state.newHashes[88] == "fakehash2"
    assert state.newEntIds[28] == "uuidv4-1"
    assert state.newEntIds[88] == "uuidv4-1"
  end

  test "handle a new merged store" do
    parsed_line1 =
      InitStores.hashParse("28,,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
      |> Map.put(:hash, "fakehash1")

    parsed_line2 =
      InitStores.hashParse("88,28,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
      |> Map.put(:hash, "fakehash2")

    state = Enum.reduce([parsed_line1, parsed_line2], ctx().emptyAcc,
      fn item, acc -> InitStores.diffFold(&IO.inspect/1, item, acc) end
      )

    assert state.oldMaps == %{}
    assert state.newHashes[28] == "fakehash1"
    assert state.newHashes[88] == "fakehash2"
    assert state.newEntIds[28] == state.newEntIds[88]
  end

  # currently not implemented
  # test "handle a new merged store out of order" do
  #   parsed_assoc_store =
  #     InitStores.hashParse("88,28,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
  #     |> Map.put(:hash, "fakehash2")

  #   parsed_main_store =
  #     InitStores.hashParse("28,,Nikelab,NSO,NikeLab,Northeast,22,NYC NSO")
  #     |> Map.put(:hash, "fakehash1")


  #   state = Enum.reduce([parsed_assoc_store, parsed_main_store], ctx().emptyAcc,
  #     fn item, acc -> InitStores.diffFold(&IO.inspect/1, item, acc) end
  #     )

  #   assert state.oldMaps == %{}
  #   assert state.newHashes[28] == "fakehash1"
  #   assert state.newHashes[88] == "fakehash2"
  #   assert state.newEntIds[28] == state.newEntIds[88]
  # end

end

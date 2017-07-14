defmodule Mix.Tasks.InitStores do
  use Mix.Task

  @shortdoc "Initialize Store Data"

  require Logger

  import Reducer.Utils, only: [gen_uuidv1: 0, gen_uuidv4: 0]

  defp getLastHashes() do
    #API call to get last hash set
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    response = HTTPoison.get!(perhap_base_url <> "/v1/model/" <>
      "storeindex/100077bd-5b34-41ac-b37b-62adbf86c1a5")

      case response do
        %HTTPoison.Response{status_code: 200, body: data} ->
          {:ok, decoded_data} = Poison.decode(data)
          makeIdMaps(decoded_data["stores"] || %{}, decoded_data["hashes"] || %{})
        %HTTPoison.Response{status_code: 404} ->
          makeIdMaps(%{}, %{})
      end
  end

  defp sendEvent(%{url: url, data: data}) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    {:ok, body} = Poison.encode(data)
    response = HTTPoison.post perhap_base_url <> "/v1/" <> url, body,
    [{"Content-Type", "application/json"}]

    case response do
      {:ok, %HTTPoison.Response{status_code: 204}} -> Logger.info("success, store number #{data.store_number}")
      _ -> Logger.info("failure, store number #{data.store_number}" )
    end

  end

  defp sendEvent(events) when is_list(events) do
    Enum.each(events, &sendEvent/1)
  end

  defp sendIndex(%{url: url, data: data}) do
    perhap_base_url = Application.get_env(:reducers, :perhap_base_url)
    {:ok, body} = Poison.encode(data)
    response = HTTPoison.post perhap_base_url <> "/v1/" <> url, body,
    [{"Content-Type", "application/json"}]

    case response do
      {:ok, %HTTPoison.Response{status_code: 204}} -> Logger.info("success, store index")
      _ -> Logger.info("failure, store index" )
    end
  end


  def run([csvfile | _args]) do
    HTTPoison.start

    idMaps = getLastHashes()

    newIdTuples =
      File.stream!(csvfile)
        |> Stream.drop(1)
        |> Stream.map(&hashParse/1)

    acc0 =
      %{oldMaps: idMaps,
        newHashes: %{},
        newEntIds: %{},
        associatedIds: %{}}

        # newTerritories %{}
        # newDistricts %{}

    %{oldMaps: _oldMaps, newHashes: newHashes, newEntIds: newEntIds} =
      Enum.reduce(newIdTuples, acc0, fn item, acc -> diffFold(&sendEvent/1, item, acc) end)

      # deactivate old stores
      # Logger.info("Map: #{inspect(oldMaps)}")
      # oldMaps
      #   |> Enum.filter_map(fn map -> map.entity_id end,
      #                      fn map -> genDeleteStoreEvent(map.entity_id) |> sendEvent end)

      # remake store index
      genStoreIndexEvent(newEntIds, newHashes) |> sendIndex

  end

  def hashParse(row_string) do
    [[storenum, associated_storenum, name, concept, subconcept, terr, distnum, distname] | _] =
      CSV.decode!([row_string]) |> Enum.to_list
    %{storenum: storenum,
      id_storenum:
        if associated_storenum == "" do nil
          else String.to_integer(associated_storenum)
        end,
      name: name,
      concept: concept,
      subconcept: subconcept,
      terr: terr,
      distnum: String.to_integer(distnum),
      distname: distname,
      hash: :crypto.hash(:sha256, row_string) |> Base.encode16 |> String.downcase()}
  end

  def diffFold(sendEventFn, row_data, state) do
    %{type: type, entity_id: uuid} =
        whichDiffType?(row_data, state.oldMaps, state.newEntIds)

    if type != :skip do
      apply(sendEventFn, [genAddStoreEvent(uuid, row_data)])
    end

    state
      |> Map.put(:oldMaps, Map.delete(state.oldMaps, row_data.storenum))
      |> put_in([:newHashes, row_data.storenum], row_data.hash)
      |> put_in([:newEntIds, row_data.storenum], uuid)
  end

  defp whichDiffType?(row_data, old_maps, newEntIds) do
    current_hash = row_data.hash
    if row_data.id_storenum do
      %{type: :skip,
        entity_id: old_maps[to_string(row_data.id_storenum)][:entity_id] || newEntIds[to_string(row_data.id_storenum)]}
        # assumes copy types created after
    else
      case old_maps[row_data.storenum] do
        nil ->
            %{type: :new,
              entity_id: gen_uuidv4()}
        %{hash: _, entity_id: nil} ->
            %{type: :new,
              entity_id: gen_uuidv4()}
        %{hash: ^current_hash, entity_id: uuid} ->
            %{type: :skip,
              entity_id: uuid}
        %{hash: _, entity_id: uuid} ->
            %{type: :edit,
              entity_id: uuid}
      end
    end
  end


#  defp genDeleteStoreEvent(entity_id) do
#    %{ url: "event/nike/store/" <>
#           "100077bd-5b34-41ac-b37b-62adbf86c1a5" <>
#           "/delete/" <> gen_uuidv1(),
#        data: %{entity_id: entity_id}
#     }
#  end

  defp genAddStoreEvent(entity_id, row_data) do
    %{url: "event/nike/store/" <> entity_id <>
          "/add/" <> gen_uuidv1(),
      data:
      %{display_name: row_data.name,
        store_number: String.to_integer(row_data.storenum),
        territory: row_data.terr,
        district: row_data.distname,
        district_id: row_data.distnum,
        concept: row_data.concept,
        subconcept: row_data.subconcept
        }
    }
  end

  defp genStoreIndexEvent(index_map, hash_map) do
     %{ url: "event/nike/storeindex/" <>
         "100077bd-5b34-41ac-b37b-62adbf86c1a5" <>
         "/replace/" <> gen_uuidv1(),
        data: %{stores: index_map, hashes: hash_map}
      }
  end

  def makeIdMaps(lastEntIds, lastHashes) do
      lastHashes
      |> Map.new(fn {num, hash} -> {num, %{hash: hash, entity_id: lastEntIds[num]}} end)
      |> Map.merge(
          Map.new(lastEntIds, fn {num, eid} -> {num, %{hash: nil, entity_id: eid}} end),
          fn _, hashV, eidV -> Map.merge(eidV, hashV) end
        )


  end
end

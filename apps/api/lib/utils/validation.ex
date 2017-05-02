defmodule API.Validation do
  @uuid_regex "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}"
  @flipped_regex "[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{12}"

  @spec is_uuid_v1(charlist()|binary()) :: true|false
  def is_uuid_v1(input) when is_list(input), do: is_uuid_v1(to_string(input))
  def is_uuid_v1(input) when is_binary(input) do
    try do
      :uuid.is_v1(:uuid.string_to_uuid(input))
    catch
      :exit, _ -> false
    end
  end

  @spec flip_v1_uuid(charlist()|binary()) :: String.t
  def flip_v1_uuid(uuid_v1) when is_list(uuid_v1) do
    flip_v1_uuid(to_string(uuid_v1))
  end
  def flip_v1_uuid(uuid_v1) when is_binary(uuid_v1) do
    [time_low, time_mid, time_high, node_hi, node_low] = String.split(uuid_v1, "-")
    time_high <> "-" <> time_mid <> "-" <> time_low <> "-" <> node_hi <> "-" <> node_low
  end

  @spec extract_datetime(charlist()|binary()) :: String.t
  def extract_datetime(uuid_v1) when is_binary(uuid_v1), do: extract_datetime(to_charlist(uuid_v1))
  def extract_datetime(uuid_v1) when is_list(uuid_v1) do
    :uuid.string_to_uuid(uuid_v1) |> :uuid.get_v1_datetime
  end

  @spec is_flipped?(charlist()|binary()) :: true|false
  def is_flipped?(input) when is_list(input), do: is_flipped?(to_string(input))
  def is_flipped?(input) when is_binary(input) do
    Regex.match?(~r/#{@flipped_regex}/, input)
  end
end

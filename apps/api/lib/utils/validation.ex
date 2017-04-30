defmodule API.Validation do
  def is_uuid_v1(input) when is_binary(input) do
    try do
      :uuid.is_v1(:uuid.string_to_uuid(input))
    catch
      :exit, _ -> false
    end
  end

  # used to order v1 uuid by time
  def uuid_v1_flip(uuidv1) do
    [time_low, time_mid, time_high, node_hi, node_low] = String.split(uuidv1, "-")
    time_high <> "-" <> time_mid <> "-" <> time_low <> "-" <> node_hi <> "-" <> node_low
  end

end

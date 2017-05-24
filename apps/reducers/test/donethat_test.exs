defmodule DonethatTest do
  use ExUnit.Case
  doctest Donethat

  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
  end

  defp random_strings(n, length) do
    for _ <- 1..n, do: random_string(length)
  end

  test "Donethat.new?" do
    rs = random_string(128)
    {true, hash_state} = Donethat.new?(rs, Donethat.empty_state())
    {false, _new_hash_state} = Donethat.new?(rs, hash_state)
  end

  test "Donethat.missing" do
    [s | rs] = random_strings(5, 128)
    hash_state1 = Enum.reduce([s | rs], Donethat.empty_state(), fn s, acc -> {_, acc} = Donethat.new?(s, acc); acc end)
    {_missing, hash_state2} = Donethat.missing(hash_state1)
    hash_state3 = Enum.reduce(rs, hash_state2, fn s, acc -> {_, acc} = Donethat.new?(s, acc); acc end)
    {missing, _hash_state} = Donethat.missing(hash_state3)
    assert missing == [s]
  end
end

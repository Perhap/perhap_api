defmodule DBTest do
  use ExUnit.Case
  doctest DB

  test "generate uuid" do
    {binary, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    result = :uuid.uuid_to_string(:uuid.get_v5_compat(binary))
    assert 36 == length(result)
  end
  
end

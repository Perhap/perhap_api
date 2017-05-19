ExUnit.start()

defmodule Reducer.Test.Helper do
  @spec gen_uuidv1() :: String.t
  def gen_uuidv1()do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    to_string(:uuid.uuid_to_string(uuid_v1))
  end

  @spec load_fixture(String.t) :: binary()
  def load_fixture(fixture_file) do
    {:ok, binary} = File.read "test/fixtures/" <> fixture_file
    binary
  end
end

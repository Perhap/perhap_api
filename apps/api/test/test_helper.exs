ExUnit.start()

defmodule API.Test.Helper do
  @spec load_fixture(String.t) :: binary()
  def load_fixture(fixture_file) do
    {:ok, binary} = File.read "test/fixtures/" <> fixture_file
    binary
  end
end

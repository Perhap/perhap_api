ExUnit.start()

defmodule API.Test.Helper do
  @spec load_fixture(String.t) :: binary()
  def load_fixture(fixture_file) do
    {:ok, binary} = File.read "test/fixtures/" <> fixture_file
    binary
  end

  def get(url) do
    :application.ensure_all_started(:gun)
    {:ok, pid} = :gun.open('localhost', 8443, %{:transport => :ssl})
    stream_ref = :gun.get(pid, url)
    read_stream(pid, stream_ref)
  end

  def post(body, url) do
    :application.ensure_all_started(:gun)
    {:ok, pid} = :gun.open('localhost', 8443, %{:transport => :ssl})
    stream_ref = :gun.post(pid, url, [
      {"content-type", 'application/json'}
    ], body)
    read_stream(pid, stream_ref)
  end

  defp read_stream(pid, stream_ref) do
    case :gun.await(pid, stream_ref) do
    	{:response, :fin, status, headers} ->
    		%{status: status, headers: headers}
    	{:response, :nofin, status, headers} ->
    		{:ok, body} = :gun.await_body(pid, stream_ref)
        %{body: body, headers: headers, status: status}
    end
  end
end

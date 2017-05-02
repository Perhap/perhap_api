defmodule ValidationTest do
  use ExUnit.Case, async: true
  alias API.Validation, as: V

  setup do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    uuid_v1_string = :uuid.uuid_to_string(uuid_v1)
    on_exit fn ->
      :ok
    end
    [uuid: uuid_v1_string]
  end

  test "can test a string for comforming to uuid_v1", ctx do
    assert false == V.is_uuid_v1("not a uuid")
    assert true == V.is_uuid_v1(ctx[:uuid])
    assert true == V.is_uuid_v1(to_string(ctx[:uuid]))
  end

  test "can flip v1 uuid", ctx do
    assert true == V.flip_v1_uuid(ctx[:uuid]) |> V.is_flipped?
    assert true == V.flip_v1_uuid(to_string(ctx[:uuid])) |> V.is_flipped?
    assert false == ctx[:uuid] |> V.is_flipped?
  end

  test "can extract time from v1 uuid" do
    uuid = 'e1c3029a-2a96-11e7-93ae-92361f002671'
    assert '2017-04-26T15:41:57.920425Z' == V.extract_datetime("#{uuid}")
    assert '2017-04-26T15:41:57.920425Z' == V.extract_datetime(uuid)
  end

end

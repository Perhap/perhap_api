defmodule Reducer.Utils do
  def gen_uuidv1() do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    to_string(:uuid.uuid_to_string(uuid_v1))
  end

  def gen_uuidv4() do
    to_string(:uuid.uuid_to_string(:uuid.get_v4(:strong)))
  end
end

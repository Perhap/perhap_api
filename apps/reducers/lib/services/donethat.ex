defmodule Donethat do
  alias HashState
  @moduledoc """
  """

  @doc """
  """

  def empty_state, do: %HashState{}

  def new?(line, %HashState{hashes: hashes, missing: missing, lines: lines}) do
    hash = hash(line)
    case hash in hashes do
      true ->
        {false, %HashState{
          hashes: hashes,
          missing: List.delete(missing, line),
          lines: [line | lines]
        }}
      _ ->
        {true, %HashState{
          hashes: [hash | hashes],
          missing: missing,
          lines: [line | lines]}}
    end
  end

  def missing(%HashState{lines: lines, missing: missing} = hash_state) do
    {missing, %HashState{hash_state | lines: [], missing: lines}}
  end

  defp hash(line), do: :crypto.hash(:sha, line) |> Base.encode16
end

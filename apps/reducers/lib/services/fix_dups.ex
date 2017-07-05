defmodule Service.Stats.Dups do
  use Mix.Task



def fix_dups(state) do
  week_stats = state["stats"]
  stats = Map.new(Enum.map(week_stats, fn {name, week} -> dedup({name, week}) end))
  Map.put(state, "stats", stats)

end

def dedup({name, week}) do
  pre = week["pre"]["actuals_meta"]
  pre_actuals = cond do
    is_nil(pre) -> %{}
    true -> Enum.uniq_by(pre, fn {k, v} -> v end)
  end
  pre_sum = Service.Stats.sum_actuals(pre_actuals)
  {pre_percentage, pre_score} = Service.Stats.accuracy(week["pre"]["pre_units"], pre_sum)

  refill = week["refill"]["actuals_meta"]
  refill_actuals = cond do
    is_nil(refill) -> %{}
    true -> Enum.uniq_by(refill, fn {k, v} -> v end)
  end
  refill_sum = Service.Stats.sum_actuals(refill_actuals)
  {refill_percentage, refill_score} = Service.Stats.accuracy(week["refill"]["refill_units"], refill_sum)

  {name,
     put_in(week, ["pre", "actuals_meta"], Map.new(pre_actuals))
  |> put_in(["pre", "actual_units"], pre_sum)
  |> put_in(["pre", "accuracy_score"], pre_score)
  |> put_in(["pre", "accuracy_percentage"], pre_percentage)
  |> put_in(["refill", "actuals_meta"], Map.new(refill_actuals))
  |> put_in(["refill", "actual_units"], refill_sum)
  |> put_in(["refill", "accuracy_score"], refill_score)
  |> put_in(["refill", "accuracy_percentage"], refill_percentage)
  }
end

end

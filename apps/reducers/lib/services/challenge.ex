defmodule Service.Challenge do
  @behaviour Reducer

  import DB.Validation, only: [flip_v1_uuid: 1]

  alias DB.Event
  alias Reducer.State

  @domains [:challenge]
  @types [:start, :stop, :edit, :actual_units, :delete]
  def domains, do: @domains
  def types, do: @types

  @spec call(list(Event.t), State.t) :: State.t
  def call(events, %State{} = state) when is_list(events) do
    {new_model, new_events} = events |> validate()
      |> challenge_reducer_recursive({state.model, []})
    %State{state | model: new_model, new_events: new_events}
  end

  def gen_uuidv1()do
    {uuid_v1, _} = :uuid.get_v1(:uuid.new(self(), :erlang))
    to_string(:uuid.uuid_to_string(uuid_v1))
  end

  def validate(event_list) do
    Enum.filter(event_list, fn(event) -> correct_type?(event) end)
    |> Enum.map( fn(event) -> event_structure(event) end)
    |> sorts_events()
  end

  def uuidv1({_type, event}) do
    event.ordered_id
  end

  def sorts_events(event_list)do
    Enum.sort(event_list, &(uuidv1(&1) < uuidv1(&2)))
  end

  def correct_type?(event) do
    Enum.member?([
      "start",
      "stop",
      "edit",
      "actual_units",
      "delete"], String.downcase(event.type))
  end

  def event_structure(%Event{event_id: event_id, meta: meta} = event) do
    type = String.to_existing_atom(String.downcase(event.type))
    data = %{
      entity_id: event.entity_id,
      domain: event.domain,
      ordered_id: flip_v1_uuid(event_id),
      # TODO:  handle missing timestamp possiblity
      # ** (ArgumentError) argument error
      #    :erlang.binary_to_integer(nil)
      timestamp: String.to_integer(meta["timestamp"]),
      data: meta
    }
    {type, data}
  end

  def challenge_reducer_recursive([], {model, new_events}), do: {model, new_events}
  def challenge_reducer_recursive([event | remaining_events], {model, new_events}) do
    challenge_reducer_recursive(remaining_events, play(event, {model, new_events}))
  end

  def play({type, event}, {model, new_events}) do
    apply(__MODULE__, type, [{type, event}, model, new_events])
  end

  def start_user(user, event, %{"status" => "stopped"} = user_model) do
    {user, user_model
    |> Map.put("status", "running")
    |> Map.put("start_time", event.timestamp)}
  end

  def start_user(user, event, user_model) when map_size(user_model) == 0 do
    {user, user_model
    |> Map.put("status", "running")
    |> Map.put("start_time", event.timestamp)}
  end

  def start_user(user, _event, user_model), do: {user, user_model}

  def start({:start, event}, model, new_events) when model == %{} do
    user_models = Enum.map(event.data["users"], fn(user) -> start_user(to_string(user), event, %{}) end)
    |> Enum.into(%{})

    {model
    |> Map.put("last_played", event.ordered_id)
    |> Map.put("users", user_models)
    |> Map.put("entity_id", event.entity_id)
    |> Map.put("domain", event.domain)
    |> Map.put("challenge_benchmark", event.data["challenge_benchmark"])
    |> Map.put("challenge_type", event.data["challenge_type"])
    |> Map.put("store_id", event.data["store_id"]),
    new_events}
  end

  def start({:start, event}, model, new_events)  do
    user_models = Enum.map(event.data["users"], fn(user) -> start_user(to_string(user), event, model["users"][to_string(user)]) end)
    |> Enum.into(model["users"])
    {model
    |> Map.put("users", user_models)
    |> Map.put("last_played", event.ordered_id), new_events}
  end

  def stop_user(user, event, %{"status" => "running", "active_seconds" => active_seconds} = user_model) do
    {user, user_model
    |> Map.put("status", "stopped")
    |> Map.put("active_seconds", ((event.timestamp - user_model["start_time"])/1000) + active_seconds)}
  end

  def stop_user(user, event, %{"status" => "running"} = user_model) do
    {user, user_model
    |> Map.put("status", "stopped")
    |> Map.put("active_seconds", ((event.timestamp - user_model["start_time"])/1000))}
  end

  def stop_user(user, _event, user_model), do: {user, user_model}


  def stop({:stop, event}, model, new_events ) when model == %{} do
    {model, new_events}
  end
  def stop({:stop, event}, model, new_events) do
    user_models = Enum.map(event.data["users"], fn(user) -> stop_user(to_string(user), event, model["users"][to_string(user)]) end)
    |> Enum.into(model["users"])
    {model
    |> Map.put("users", user_models)
    |> Map.put("last_played", event.ordered_id), new_events}
  end

  def actual_units_user(user, %{:data => %{"units" => units}} = event, %{"status" => "stopped"} = user_model, benchmark) when is_number(units) do
    units = event.data["units"]
    users = length(event.data["users"])
    actual_units = units / users
    uph = actual_units / (user_model["active_seconds"] / 3600)
    percentage = uph/ benchmark

    new_model = user_model
      |> Map.put("status", "completed")
      |> Map.put("actual_units", actual_units)
      |> Map.put("uph", uph)
      |> Map.put("percentage", percentage)
      {user, new_model}
  end

  def actual_units_user(user, event, %{"status" => "stopped"} = user_model, benchmark) do
    {units, _} = Float.parse(event.data["units"])
    users = length(event.data["users"])
    actual_units = units / users
    uph = actual_units / (user_model["active_seconds"] / 3600)
    percentage = uph/ benchmark

    new_model = user_model
      |> Map.put("status", "completed")
      |> Map.put("actual_units", actual_units)
      |> Map.put("uph", uph)
      |> Map.put("percentage", percentage)
      {user, new_model}
  end

  def actual_units_user(user, _event, user_model, _benchmark), do: {user, user_model}

  def actual_units({:actual_units, event}, model, new_events ) when model == %{} do
    {model, new_events}
  end
  def actual_units({:actual_units, event}, model, new_events ) do
    user_models = Enum.map(event.data["users"], fn(user) -> actual_units_user(to_string(user), event, model["users"][to_string(user)], model["challenge_benchmark"]) end)
    |> Enum.into(model["users"])

    new_model = model
    |> Map.put("users", user_models)
    |> Map.put("last_played", event.ordered_id)
    {new_model, create_stats_event(stats_type(new_model["challenge_type"]), new_model, new_events)}
  end

  def edit_user(user, _event, %{"status" => "deleted"} = user_model, _benchmark), do: {user, user_model}
  def edit_user(user, %{:data => %{"units" => units}} = event, %{"status" => "stopped"} = user_model, benchmark) when is_number(units) do
    actual_units = event.data["units"] / length(event.data["users"])
    uph = actual_units / (event.data["duration_min"] / 60)
    percentage = uph/ benchmark

    {user, user_model
      |> Map.put("status", "editted")
      |> Map.put("active_seconds", event.data["duration_min"] * 60)
      |> Map.put("actual_units", actual_units)
      |> Map.put("uph", uph)
      |> Map.put("percentage", percentage)
    }
  end

  def edit_user(user, event, user_model, benchmark) do
    {units, _} = Float.parse(event.data["units"]) 
    actual_units= units / length(event.data["users"])
    uph = actual_units / (event.data["duration_min"] / 60)
    percentage = uph/ benchmark

    {user, user_model
      |> Map.put("status", "editted")
      |> Map.put("active_seconds", event.data["duration_min"] * 60)
      |> Map.put("actual_units", actual_units)
      |> Map.put("uph", uph)
      |> Map.put("percentage", percentage)
    }
  end

  def edit({:edit, event}, model, new_events ) when model == %{} do
    {model, new_events}
  end
  def edit({:edit, event}, model, new_events) do
    user_models = Enum.map(event.data["users"], fn(user) -> edit_user(to_string(user), event, model["users"][to_string(user)], model["challenge_benchmark"]) end)
    |> Enum.into(model["users"])
    new_model = model
    |> Map.put("users", user_models)
    |> Map.put("last_played", event.ordered_id)
    {new_model, create_stats_event(stats_type(new_model["challenge_type"]), new_model, new_events)}
  end

  def stats_type(challenge_type)do
    case challenge_type do
      "equipment" -> "pre_challenge_transform"
      "apparel" -> "pre_challenge_transform"
      "footwear" -> "pre_challenge_transform"
      "product_refill" -> "refill_challenge_transform"
      _ -> :reject
    end
  end

  def create_stats_event(:reject, _, new_events), do: new_events
  def create_stats_event(type, model, new_events) do
    meta = Map.drop(model, ["last_played", "domain", "entity_id"])
    |> Map.put("challenge_id", model["entity_id"])
    [%Event{
      type: type,
      domain: "transformer",
      realm: "nike",
      entity_id: model["entity_id"],
      meta: meta,
      event_id: gen_uuidv1(),
      remote_ip: "127.0.0.1"
    } | new_events]
  end

  def delete_user(user, _event, user_model) do
    new_model = user_model
      |> Map.put("status", "deleted")
      |> Map.drop(["active_seconds", "actual_units", "uph", "percentage"])
    {user, new_model}
  end


  def delete({:delete, event}, model, new_events ) when model == %{} do
    {model, new_events}
  end
  def delete({:delete, event}, model, new_events) do
    user_models = Enum.map(event.data["users"], fn(user) -> delete_user(to_string(user), event, model["users"][to_string(user)]) end)
    |> Enum.into(model["users"])
    new_model = model
    |> Map.put("users", user_models)
    |> Map.put("last_played", event.ordered_id)
    {new_model, create_stats_event(stats_type(new_model["challenge_type"]), new_model, new_events)}
  end



end

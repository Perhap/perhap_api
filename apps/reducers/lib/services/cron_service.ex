defmodule Service.Cron do
  import Reducer.Utils, only: [gen_uuidv1: 0]

  require Logger

  def bin_audit_event() do
    env = Application.get_env(:reducers, :domo_creds)
    entity_id = "ea43de77-366f-4758-a8cc-f27bf9f622b9"
    eventdata = %{
        "out_going_type" => Keyword.get(env, :bin_audit_type),
        "out_going_domain" => "stats",
        "dataset_id" => Keyword.get(env, :bin_audit_dataset),
        "client_id" => Keyword.get(env, :client_id),
        "client_secret" => Keyword.get(env, :client_secret)
    }
    event_id = gen_uuidv1()
    {_, data} =Poison.encode(eventdata)

    _url = "https://perhap/bigsquidapp.com/v1/event/domo/" <> entity_id <> "/pull/" <> event_id

    HTTPoison.post("https://requestb.in/q8usdhq8", data, [], [])
  end

  def actuals_event() do
    env = Application.get_env(:reducers, :domo_creds)
    entity_id = "9f3f1763-d2e8-45cd-8e5c-89ff038a95f5"
    eventdata = %{
        "out_going_type" => Keyword.get(env, :actuals_type),
        "out_going_domain" => "stats",
        "dataset_id" => Keyword.get(env, :actuals_dataset),
        "client_id" => Keyword.get(env, :client_id),
        "client_secret" => Keyword.get(env, :client_secret)
    }
    event_id = gen_uuidv1()
    {_, data} =Poison.encode(eventdata)

    _url = "https://perhap/bigsquidapp.com/v1/event/domo/" <> entity_id <> "/pull/" <> event_id

    HTTPoison.post("https://requestb.in/q8usdhq8", data, [], [])
  end

  def test() do
    Logger.info("From Cron")
  end
end

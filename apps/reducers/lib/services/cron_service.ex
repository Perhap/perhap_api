defmodule Service.Cron do
  import Reducer.Utils, only: [gen_uuidv1: 0]

  require Logger

  def bin_audit_get() do
    env = Application.get_env(:reducers, :domo_creds)
    dataset_info = %{
        "out_going_type" => Keyword.get(env, :bin_audit_type),
        "out_going_domain" => "stats",
        "dataset_id" => Keyword.get(env, :bin_audit_dataset),
        "client_id" => Keyword.get(env, :client_id),
        "client_secret" => Keyword.get(env, :client_secret),
        "field_name"=> "STORE"
    }
    Service.Domo.domo_service(dataset_info)
  end

  def actuals_get() do
    env = Application.get_env(:reducers, :domo_creds)
    dataset_info = %{
        "out_going_type" => Keyword.get(env, :actuals_type),
        "out_going_domain" => "stats",
        "dataset_id" => Keyword.get(env, :actuals_dataset),
        "client_id" => Keyword.get(env, :client_id),
        "client_secret" => Keyword.get(env, :client_secret),
        "field_name"=> "Store"
    }
    Service.Domo.domo_service(dataset_info)
  end

  def apa_get() do
    env = Application.get_env(:reducers, :domo_creds)
    dataset_info = %{
        "out_going_type" => Keyword.get(env, :apa_type),
        "out_going_domain" => "stats",
        "dataset_id" => Keyword.get(env, :apa_dataset),
        "client_id" => Keyword.get(env, :client_id),
        "client_secret" => Keyword.get(env, :client_secret),
        "field_name"=> "store_id"
    }
    Service.Domo.domo_service(dataset_info)
  end

  def heartbeat() do
    Logger.debug("Cron: Heartbeat")
  end
end

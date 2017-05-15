defmodule Plug.Monitoring do
  @behaviour Plug
  import Plug.Conn, only: [register_before_send: 2]

  alias :exometer, as: Exometer

  require Logger

  def init(opts), do: opts

  def call(conn, _config) do
    path_info = Enum.at(conn.path_info, 1)
    method = conn.method
    metric_name = [path_info, method]
    before_time = System.monotonic_time()
    register_before_send(conn, fn conn ->
      after_time = System.monotonic_time()
      diff = System.convert_time_unit(after_time - before_time, :native, :microseconds) / 1000
      update_stat(metric_name ++ [:counter], 1, :counter)
      update_stat(metric_name ++ [:spiral], 1, :spiral)
      update_stat(metric_name ++ [:histogram], diff, :histogram)
      Logger.info("#{path_info},#{method}/#{diff}ms", perhap_only: 1)
      conn
    end)
  end

  def update_stat(stat, value, type \\ :counter) do
    case Exometer.update(stat, value) do
      {:error, :not_found} ->
        Exometer.new(stat, type)
        update_stat(stat, value)
      :ok ->
        :ok
    end
  end

end

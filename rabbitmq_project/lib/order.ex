defmodule CALC.Order do
  require Logger

  def work(pids) do
    num_pids = Enum.random(1..MyConfig.get("order_max_pids"))
    our_pids = Enum.take_random(pids,num_pids)
    :lists.foreach(fn pid -> GenServer.call(pid,{:remove,Enum.random(1..MyConfig.get("order_max_items"))}) end, our_pids)
    :timer.sleep(Enum.random( 100 .. MyConfig.get("order_sleep_time")))
    work(pids)
  end
end

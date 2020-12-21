defmodule CALC.Order do
  require Logger

  def work(pids) do
    num_pids = Enum.random(1..CALC.Constants.Order.max_pids)
    our_pids = Enum.take_random(pids,num_pids)
    :lists.foreach(fn pid -> GenServer.call(pid,{:remove,Enum.random(1..CALC.Constants.Order.max_items)}) end, our_pids)
    :timer.sleep(Enum.random( 100 .. CALC.Constants.Order.sleep_time))
    work(pids)
  end
end

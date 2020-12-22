defmodule CALC.Resupply do
  use GenServer
  require Logger
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [] , name: {:global, :resupply})
  end
  def init(_args) do
    Process.spawn(__MODULE__,:wait_and_go,[self()],[])
    {:ok, []}
  end

  def handle_cast({:resupply,pid},[]) do
    {:noreply, [pid]}
  end

  def handle_cast({:resupply,pid},state) do
    {:noreply,[ pid | state ]}
  end

  def handle_cast(:go,state) do
    :lists.foreach(fn pid ->
      GenServer.cast(pid, {:add,MyConfig.get("resuply_add_number")})
    end, state)
    {:noreply,[]}
  end

  def wait_and_go(parent_pid) do
    :timer.sleep(MyConfig.get("resupply_sleep_time"))
    Logger.info("resupplying")
    GenServer.cast(parent_pid,:go)
    wait_and_go(parent_pid)
  end


end

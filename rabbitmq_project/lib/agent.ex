defmodule CALC.Agent do
  use GenServer
  require Logger

  def start(key, amount, resupply_pid) do
    GenServer.start_link(__MODULE__, {key, amount, resupply_pid}, name: {:global, :"#{key}_agent"})
  end

  def init({key, amount, resupply_pid}) do
    {:ok, %{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: true}}

  end


  def handle_cast({:add, add_amount},%{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: _resupplied}) do
    #TODO : modify table
    :ok = :dets.insert(:products,{key,amount+add_amount})
    Logger.info("added #{add_amount} #{key}")
    {:noreply,%{key: key, amount: amount + add_amount, resupply_pid: resupply_pid, resupplied: true}} #{:continue,{:check_notif,amount}}}
  end


  def handle_call({:remove,rem_amount},_from,%{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: resupplied}) do
    #TODO : get & modify table
    case amount - rem_amount > 0 do
      true ->
        :dets.insert(:products,{key,amount-rem_amount})
        Logger.info("removed #{rem_amount} #{key}")
        if amount - rem_amount <= CALC.Constants.Agent.min do
          case resupplied do
            true ->
              GenServer.cast(resupply_pid,{:resupply,self()})
              {:reply, :ok, %{key: key, amount: amount - rem_amount, resupply_pid: resupply_pid, resupplied: false}} #{:continue,{:check_notif,amount}}}
            _ ->
              {:reply, :ok, %{key: key, amount: amount - rem_amount, resupply_pid: resupply_pid, resupplied: false}} #{:continue,{:check_notif,amount}}}
          end
        else
          {:reply, :ok, %{key: key, amount: amount - rem_amount, resupply_pid: resupply_pid, resupplied: resupplied}} #{:continue,{:check_notif,amount}}}
        end
      false ->
        {:reply, :error, %{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: resupplied}}
    end

  end

  def handle_continue({:check,_prev_amount},%{key: key, amount: amount}) do
    #TODO : map on the notif thresholds and determine those that are affected
    # then send rabbitmq message
    {:noreply,%{key: key, amount: amount}}
  end
end

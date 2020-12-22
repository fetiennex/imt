defmodule CALC.Agent do
  use GenServer
  require Logger

  def start(key, amount, resupply_pid, channel) do
    GenServer.start_link(__MODULE__, {key, amount, resupply_pid, channel }, name: {:global, :"#{key}_agent"})
  end

  def init({key, amount, resupply_pid, channel}) do

    {:ok, %{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: true, channel: channel}}

  end


  def handle_cast({:add, add_amount},%{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: _resupplied, channel: channel}) do
    #TODO : modify table
    :ok = :dets.insert(:products,{key,amount+add_amount})
    Logger.info("added #{add_amount} #{key}")
    {:noreply,%{key: key, amount: amount + add_amount, resupply_pid: resupply_pid, resupplied: true, channel: channel}, {:continue,{:check_notif,amount}}}
  end


  def handle_call({:remove,rem_amount},_from,%{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: resupplied, channel: channel}) do
    #TODO : get & modify table
    case amount - rem_amount >= 0 do
      true ->
        :dets.insert(:products,{key,amount-rem_amount})
        Logger.info("removed #{rem_amount} #{key}")
        if amount - rem_amount <= MyConfig.get("agent_min_before_resupply") do
          case resupplied do
            true ->
              GenServer.cast(resupply_pid,{:resupply,self()})
              {:reply, :ok, %{key: key, amount: amount - rem_amount, resupply_pid: resupply_pid, resupplied: false, channel: channel}, {:continue,{:check_notif,amount}}}
            _ ->
              {:reply, :ok, %{key: key, amount: amount - rem_amount, resupply_pid: resupply_pid, resupplied: false, channel: channel}, {:continue,{:check_notif,amount}}}
          end
        else
          {:reply, :ok, %{key: key, amount: amount - rem_amount, resupply_pid: resupply_pid, resupplied: resupplied, channel: channel}, {:continue,{:check_notif,amount}}}
        end
      false ->
        {:reply, :error, %{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: resupplied, channel: channel}}
    end

  end

  def handle_continue({:check_notif,prev_amount},%{key: key, amount: amount, resupply_pid: resupply_pid, resupplied: resupplied, channel: channel}) do
    #TODO : map on the notif thresholds and determine those that are affected
    # then send rabbitmq message
    if prev_amount < amount do
      #RABBITMQ: Resupplied
      AMQP.Basic.publish(channel,"calc_exchange","#{key}.resupplied", "#{key} was resupplied")
      Logger.info("published on #{key}.resupplied")
    end

    :lists.foreach(fn thre ->
      if prev_amount > thre && amount <= thre do
        #RABBITMQ #{thre}#{key} left
        AMQP.Basic.publish(channel,"calc_exchange","#{key}.#{thre}", "#{key} has #{thre} left")
        Logger.info("published on #{key}.#{thre}")
      end
    end,MyConfig.get("rabbitmq_thresholds"))

    {:noreply,%{key: key, amount: amount,resupply_pid: resupply_pid, resupplied: resupplied, channel: channel}}
  end
end

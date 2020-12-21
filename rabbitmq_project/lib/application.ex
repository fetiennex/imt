defmodule CALC.Application do
  @moduledoc """
  Documentation for `RabbitmqProject`.
  """
  use Application

  @doc """
  """
  def start(_type, _args) do
    #TODO: lancer les dynamicsupervisor. create_table creéera les process à appeler.
    File.rm(File.cwd! <> "/products")
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: CALC.AgentSupervisor,max_restarts: 1000,restart: :transient},
      {DynamicSupervisor, strategy: :one_for_one, name: CALC.OrderSupervisor,max_restarts: 1000,restart: :transient},
      CALC.Resupply
    ]
    opts = [strategy: :one_for_one, name: CALC.MainSupervisor]
    result = Supervisor.start_link(children, opts)
    resupply_pid = :global.whereis_name(:resupply)
    create_table(resupply_pid)
    create_orders(5)
    result
  end

  def create_orders(num) do
    nums = Enum.to_list(0..num)
    pids = DynamicSupervisor.which_children(CALC.AgentSupervisor)
    real_pids = Enum.map(pids,fn {_,pid,_,_} -> pid end)
    :lists.foreach(fn num ->
      DynamicSupervisor.start_child(CALC.OrderSupervisor, %{id: num, start: {CALC.Order, :work, [real_pids]},restart: :transient })
    end, nums)
  end

  def create_table(resupply_pid) do

    raw_table = File.cwd! <> "/lib/products.json"
    |> File.read!
    |> Poison.decode!

    {:ok, _table} = :dets.open_file(:products, [type: :set])
    :lists.foreach(fn %{"key"=>key,"amount"=>amount} ->
      DynamicSupervisor.start_child(CALC.AgentSupervisor, %{id: key, start: {CALC.Agent, :start, [key,amount,resupply_pid]},restart: :transient })
      :dets.insert_new(:products, {key,amount} )
    end,
    raw_table["products"])

  end

end

defmodule CALC.Application do
  @moduledoc """
  Documentation for `RabbitmqProject`.
  """
  use Application

  @doc """
  """
  def start(_type, _args) do
    #TODO: lancer les dynamicsupervisor. create_table creéera les process à appeler.
    node_name = get_node_name()

    if node_name == "client" do
      opts = [strategy: :one_for_one, name: CALC.ClientSupervisor]
      children = generate_random_clients(5)
      result = Supervisor.start_link(children, opts)
      IO.puts(inspect children)
      result
    else
      File.rm(File.cwd! <> "/products")

      {:ok, connection} = AMQP.Connection.open(CALC.Constants.RabbitMQ.options)
      {:ok, channel} = AMQP.Channel.open(connection)
      AMQP.Exchange.declare(channel, "calc_exchange",:direct)

      children = [
        {DynamicSupervisor, strategy: :one_for_one, name: CALC.AgentSupervisor,max_restarts: 1000,restart: :transient},
        {DynamicSupervisor, strategy: :one_for_one, name: CALC.OrderSupervisor,max_restarts: 1000,restart: :transient},
        CALC.Resupply
      ]
      opts = [strategy: :one_for_one, name: CALC.MainSupervisor]
      result = Supervisor.start_link(children, opts)
      resupply_pid = :global.whereis_name(:resupply)
      create_table(resupply_pid,channel)
      create_orders(5)

      result
    end

  end

  def get_node_name do
    node = Node.self()
    [node_at] = Regex.run(~r/.*\@/,inspect node)
    [node_name] = Regex.run(~r/\w.*[^@]/,node_at)
    node_name
  end

  def create_orders(num) do
    nums = Enum.to_list(0..num)
    pids = DynamicSupervisor.which_children(CALC.AgentSupervisor)
    real_pids = Enum.map(pids,fn {_,pid,_,_} -> pid end)
    :lists.foreach(fn num ->
      DynamicSupervisor.start_child(CALC.OrderSupervisor, %{id: num, start: {CALC.Order, :work, [real_pids]},restart: :transient })
    end, nums)
  end

  def create_table(resupply_pid,channel) do

    raw_table = File.cwd! <> "/lib/products.json"
    |> File.read!
    |> Poison.decode!

    {:ok, _table} = :dets.open_file(:products, [type: :set])
    :lists.foreach(fn %{"key"=>key,"amount"=>amount} ->
      DynamicSupervisor.start_child(CALC.AgentSupervisor, %{id: key, start: {CALC.Agent, :start, [key,amount,resupply_pid,channel]},restart: :transient })
      :dets.insert_new(:products, {key,amount} )
    end,
    raw_table["products"])

  end

  def generate_random_clients(num) do

    raw_table = File.cwd! <> "/lib/products.json"
    |> File.read!
    |> Poison.decode!
    list_keys = Enum.map(raw_table["products"], fn %{"key"=>key, "amount"=>_amount} -> key end)
    list_thresholds = ["resupplied" | CALC.Constants.RabbitMQ.thresholds()]
    children = []
    children = for x <- 1..num do

      rand_num_keys = Enum.random(1..CALC.Constants.RabbitMQ.max_keys_sub())
      our_keys = Enum.take_random(list_keys,rand_num_keys)
      bindings = []
      bindings = for key <- our_keys do
        rand_num_thresholds = Enum.random(1..CALC.Constants.RabbitMQ.max_thre_sub())
        our_thresholds = Enum.take_random(list_thresholds,rand_num_thresholds)
        bindings = bindings ++ Enum.map(our_thresholds, fn thre -> "#{key}.#{thre}" end )
      end
      flat_bindings = List.flatten(bindings)
      children = children ++
        %{id: "#{x}",
        start: {CALC.Client, :init, ["client_#{x}",flat_bindings]}
        }
    end
  end
end

defmodule CALC.Application do
  @moduledoc """
  Documentation for `RabbitmqProject`.
  """
  use Application

  @doc """
  """
  def start(_type, _args) do
    #TODO: lancer les dynamicsupervisor. create_table creéera les process à appeler.
    MyConfig.load(File.cwd! <> "/config.json")
    IO.puts(inspect MyConfig.get("rabbitmq_options"))
    node_name = get_node_name()

    if node_name == "client" do
      opts = [strategy: :one_for_one, name: CALC.ClientSupervisor]
      children = generate_random_clients(MyConfig.get("rabbitmq_rand_clients_num"))
      children = children ++ generate_json_clients()
      result = Supervisor.start_link(children, opts)
      IO.puts(inspect children)
      result
    else
      File.rm(File.cwd! <> "/products")
      {:ok, connection} = AMQP.Connection.open(MyConfig.get_rabbit_options) #MyConfig.get("rabbitmq_options"))
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
      create_orders(MyConfig.get("order_num_orders"))

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

    raw_table = File.cwd! <> "/products.json"
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

    raw_table = File.cwd! <> "/products.json"
    |> File.read!
    |> Poison.decode!
    list_keys = Enum.map(raw_table["products"], fn %{"key"=>key, "amount"=>_amount} -> key end)
    list_thresholds = ["resupplied" | MyConfig.get("rabbitmq_thresholds")]
    children = []
    children = for x <- 1..num do

      rand_num_keys = Enum.random(1..MyConfig.get("rabbitmq_max_keys_sub"))
      our_keys = Enum.take_random(list_keys,rand_num_keys)
      bindings = []
      bindings = for key <- our_keys do
        rand_num_thresholds = Enum.random(1..MyConfig.get("rabbitmq_max_thre_sub"))
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

  def generate_json_clients() do
    raw_table = File.cwd! <> "/clients.json"
    |> File.read!
    |> Poison.decode!

    children = Enum.map(raw_table["clients"], fn %{"name"=>name, "bindings" => bindings} -> %{id: "#{name}", start: {CALC.Client, :init, ["#{name}",bindings]}
    } end )

  end
end


defmodule CALC.Client do
  require Logger

  def init(name,bindings) do
    spawn_link(fn -> start_queue(name,bindings) end)
    {:ok, self()}
  end
  def start_queue(name, bindings) do
    IO.puts(inspect bindings)
    IO.puts(".........")
    {:ok, connection} = AMQP.Connection.open(MyConfig.get_rabbit_options())
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Exchange.declare(channel, "calc_exchange", :direct)
    {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, "")

    :lists.foreach(fn binding -> AMQP.Queue.bind(channel, queue_name, "calc_exchange", routing_key: binding)
    IO.puts("binded #{name} to #{binding}")
  end , bindings)

    #AMQP.Basic.qos(channel, prefetch_count: 1)
    AMQP.Basic.consume(channel, queue_name , nil, no_ack: true)
    Logger.info("[x] #{name} started listening to queue")
    wait_for_messages(name)
  end

  def wait_for_messages(name) do
    receive do
      {:basic_deliver, payload, meta} ->

        IO.puts " [x] #{name} received a notification : #{payload} [#{meta.routing_key}]"
        wait_for_messages(name)
    end
  end

end

#CALC.Client.init("toto",["peche.5"])

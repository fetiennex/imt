options = [host: "172.17.0.2", port: 5672]
{:ok, connection} = AMQP.Connection.open(options)
{:ok, channel} = AMQP.Channel.open(connection)

AMQP.Queue.declare(channel, "hello")

AMQP.Basic.publish(channel, "", "hello", "Hello World!")
IO.puts " [x] Sent 'Hello World!'"
AMQP.Connection.close(connection)

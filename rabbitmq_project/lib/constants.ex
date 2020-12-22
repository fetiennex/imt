defmodule CALC.Constants do

  defmodule Resupply do
    def add_number, do: 10
    def sleep_time, do: 10000
  end

  defmodule Order do
    def num_orders, do: 5
    def max_pids, do: 5
    def max_items, do: 3
    def sleep_time, do: 1000
  end

  defmodule Agent do
    def min, do: 3
  end

  defmodule RabbitMQ do
    def options, do: [host: "172.17.0.2", port: 5672]
    def thresholds, do: [0, 1, 5, 10, 30]
    def max_keys_sub, do: 1
    def max_thre_sub, do: 2
    def rand_clients_num, do: 5

  end

end

defmodule ImtOrder.App do
  use Supervisor
  def start_link(_) do

    Supervisor.start_link([{DynamicSupervisor, strategy: :one_for_one, name: MyApp.DynamicSupervisor,max_restarts: 1000,restart: :transient}], strategy: :one_for_one)
    Supervisor.start_link([
        ImtOrder.StatsToDb,
        {Plug.Cowboy, scheme: :http, plug: ImtOrder.API, options: [port: 9090]}
      ], strategy: :one_for_one)
  end
end

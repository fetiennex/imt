defmodule ImtSandbox.App do
  use Application
  def start(_,_) do
    Supervisor.start_link([
        ImtOrder.App,
        ImtSim.Back,
        ImtSim.Front,
      ], strategy: :one_for_one)
  end
end

# in this file : all module for backend simulation :
# generate stocks and stats, and receive orders

defmodule ImtSim.Back do
  use Supervisor
  def start_link(_) do
    Supervisor.start_link([
      ImtSim.Back.Stocks,
      ImtSim.Back.Stats,
      {Plug.Cowboy, scheme: :http, plug: ImtSim.Back.OrderReceiver, options: [port: 9091]}
    ], strategy: :one_for_one)
  end
end

defmodule ImtSim.Back.Stocks do
  use GenServer
  @timeout 5_000
  def start_link(_) do GenServer.start_link(__MODULE__,[],name: __MODULE__) end
  def init([]) do {:ok,[],@timeout} end
  def handle_info(:timeout,[]) do gen_stockfile(); {:noreply,[],@timeout} end

  def gen_stockfile() do
    # generate stocks for 10_000 prods in 200 stores : IDPROD,IDSTORE,QUANTITY
    file = 1..10_000 |> Enum.reduce([],fn prod_id,acc->
      1..200 |> Enum.reduce(acc,fn store_id,acc->
        # stock from 0 to 15, half of the time stock of 0 !
        ["#{prod_id},#{store_id},#{max(0,:rand.uniform(30)-15)}\n"|acc]
      end)
    end)
    :httpc.request(:put,{'http://localhost:9090/stocks',[],'text/csv',IO.iodata_to_binary(file)},[],[])
  end
end

defmodule ImtSim.Back.Stats do
  use GenServer
  @timeout 10_000
  def start_link(_) do GenServer.start_link(__MODULE__,[],name: __MODULE__) end
  def init([]) do {:ok,[],@timeout} end
  def handle_info(:timeout,[]) do gen_statfile(); {:noreply,[],@timeout} end

  def gen_statfile() do
    # generate 10_000 product line : IDPROD,NBVENTE,PRIXVENTE
    file = 1..10_000 |> Enum.reduce([],fn prod_id,acc->
      ["#{prod_id},#{:rand.uniform(30)},#{:rand.uniform(30)}\n"|acc]
    end)
    padded_ts = String.pad_leading("#{:erlang.system_time(:millisecond)}",15,["0"])
    File.write!("data/stat_#{padded_ts}.csv", file)
    IO.puts "stat file data/stat_#{padded_ts}.csv generated"
  end
end

defmodule ImtSim.Back.OrderReceiver do
  use Plug.Router
  #plug Plug.Logger
  plug :match
  plug :dispatch

  post "/order/new" do
    :timer.sleep(2_000 + (:rand.uniform(8)*250))
    conn |> send_resp(200,"") |> halt()
  end

  post "/order/process_delivery" do
    case :rand.uniform(4) do
      1 -> conn |> send_resp(504,"") |> halt()
      _ -> conn |> send_resp(200,"") |> halt()
    end

  end

  match _ do
    conn
  end
end

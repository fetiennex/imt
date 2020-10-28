# in this file : all module for frontend simulation :
# send commit order queries... and stat queries
defmodule ReqSender do
  use GenServer
  def start_link(opts) do GenServer.start_link(__MODULE__, opts, name: __MODULE__) end
  def init(opts) do
    Process.send_after(self(),:stop,opts[:duration]*1000)
    Process.send_after(self(),:sendreq,0)
    todo = opts[:todo] |> Enum.map(fn {c,fun}-> List.duplicate(fun,c) end) |> Enum.concat
    {:ok,%{id: 0, c: 0, parent: opts[:parent], running: true,
        req_interval: div(1000,opts[:rate] || 10), todo: todo}}
  end
  def handle_info(:sendreq,%{running: false}=s) do {:noreply,s} end
  def handle_info(:sendreq,%{running: true,id: id}=s) do
    sender = self(); fun = Enum.random(s.todo)
    spawn_link fn-> fun.(id); send(sender,:reqdone) end
    Process.send_after(self(),:sendreq,s.req_interval)
    {:noreply,%{s|c: s.c + 1, id: s.id + 1}}
  end
  def handle_info(:reqdone,s) do {:noreply,maybe_end(%{s|c: s.c - 1})} end
  def handle_info(:stop,s) do {:noreply,maybe_end(%{s|running: false})} end

  def maybe_end(%{running: false, c: 0, parent: parent}=s) do send(parent,:endtest) ; s end
  def maybe_end(%{c: c}=s) when rem(c,10000) == 0 do IO.write(:stderr,".") ; s end
  def maybe_end(s) do s end
end

defmodule Req do
  @url 'http://localhost:9090/'
  def get_req_ko400(id,path,logfile) do
    ts = :erlang.system_time(:milli_seconds)
    {time,{ok?,other}} = :timer.tc(fn ->
      case :httpc.request('#{@url}#{path}') do
        {:ok,{{_,code,_},_,_}} when code < 400-> {:ok,code}
        {:ok,{{_,code,_},_,_}}-> {:ko,code}
        {:error,reason}-> {:ko,"#{inspect reason}"}
      end
    end)
    IO.write(logfile,"#{id},#{ts},#{String.replace(path,",","-")},#{div(time,1000)},#{ok?},#{other}\n")
  end

  def post_random_order(req_id,logfile) do
    order = Poison.encode!(%{
      id: "#{req_id}",
      products: [
        %{id: :rand.uniform(1000), quantity: :rand.uniform(5)},
        %{id: :rand.uniform(1000), quantity: :rand.uniform(5)}
      ]
    })
    ts = :erlang.system_time(:milli_seconds)
    spawn_link(fn ->
      {time,{ok?,other}} = :timer.tc(fn ->
        case :httpc.request(:post,{'#{@url}/order',[],'application/json',order},[],[]) do
          {:ok,{{_,code,_},_,_}} when code < 400-> {:ok,code}
          {:ok,{{_,code,_},_,_}}-> {:ko,code}
          {:error,reason}-> {:ko,"#{inspect reason}"}
        end
      end)
      IO.write(logfile,"#{req_id},#{ts},/orders,#{div(time,1000)},#{ok?},#{other}\n")
    end)
    spawn_link(fn->
      :timer.sleep(10_000) # le paiement arrive après la commande
      post_payment(req_id,logfile)
    end)
  end

  def post_payment(order_id,logfile) do
    transaction = Poison.encode!(%{transaction_id: :rand.uniform(10_000)})
    ts = :erlang.system_time(:milli_seconds)
    {time,{ok?,other}} = :timer.tc(fn ->
      case :httpc.request(:post,{'#{@url}/order/#{order_id}/payment-callback',[],'application/json',transaction},[],[]) do
        {:ok,{{_,code,_},_,_}} when code < 400-> {:ok,code}
        {:ok,{{_,code,_},_,_}}-> {:ko,code}
        {:error,reason}-> {:ko,"#{inspect reason}"}
      end
    end)
    IO.write(logfile,"#{900000000+order_id},#{ts},/order/#{order_id}/payment-callback',#{div(time,1000)},#{ok?},#{other}\n")
  end
end

defmodule ImtSim.Front do
  use Supervisor
  def start_link(_) do
    logfile = File.open!("data/stats.csv",[:write])
    Supervisor.start_link([
        {ReqSender, parent: self(), rate: 10, duration: 30, todo: [
          {10,&Req.get_req_ko400(&1,"/aggregate-stats/#{:rand.uniform(1000)}",logfile)},
          {1,&Req.post_random_order(&1,logfile)},
         ]}
       ], strategy: :one_for_one)
  end
end

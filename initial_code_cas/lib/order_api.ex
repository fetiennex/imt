defmodule ImtOrder.API do
  use Plug.Router
  #plug Plug.Logger
  plug :match
  plug :dispatch

  get "/aggregate-stats/:product" do
    #IO.puts "get stat for #{product}"

    parent = self()
    res =
      ImtOrder.StatsToDb.get(product)
        |> Stream.chunk_every(1000)
        |> Enum.map(fn chunk->
          spawn_link fn->
            res = Enum.reduce(chunk,%{ca: 0, total_qty: 0}, fn {sold_qty,price}, acc ->
              %{acc|
                 ca: acc.ca + sold_qty * price,
                 total_qty: acc.total_qty + sold_qty
               }
            end)
            send(parent,{self(),res})
          end
        end)
        |> Enum.reduce(%{ca: 0, total_qty: 0}, fn _, acc ->
          receive do
            {_,partial_res}-> %{acc| ca: acc.ca + partial_res.ca, total_qty: acc.total_qty + partial_res.total_qty}
          end
        end)
      #        |> Enum.reduce(%{n: 0, ca: 0, total_qty: 0}, fn {sold_qty,price}, acc ->
      #          %{acc|
      #            n: acc.n + 1,
      #             ca: acc.ca + sold_qty * price,
      #             total_qty: acc.total_qty + sold_qty
      #           }
      #        end)

    res = Map.put(res, :mean_price, res.ca / (if res.total_qty == 0, do: 1, else: res.total_qty))
    # IO.inspect res
    conn |> send_resp(200, Poison.encode!(res)) |> halt()
  end

  put "/stocks" do
    {:ok,bin,conn} = read_body(conn,length: 100_000_000)
    for line<-String.split(bin,"\n") do
      case String.split(line,",") do
        [_,_,_]=l->
          [prod_id,store_id,quantity] = Enum.map(l,&String.to_integer/1)
          MicroDb.HashTable.put("stocks",{store_id,prod_id},quantity)
        _-> :ignore_line
      end
    end
    conn |> send_resp(200,"") |> halt()
  end

  # Choose first store containing all products and send it the order !
  post "/order" do
    require Logger

    {:ok,bin,conn} = read_body(conn)
    order = Poison.decode!(bin)

    child = DynamicSupervisor.start_child(MyApp.DynamicSupervisor, %{id: order["id"], start: {OrderTransactor, :start, [order["id"],order]}})

    case child do
      {:ok, pid} ->
        Logger.info(["[Create] ", inspect(Process.info(pid)[:registered_name]) ," created"])
        conn |> send_resp(200,"") |> halt()
      err ->
        Logger.error("[Create] Error #{inspect err}")
        conn |> send_resp(500,"") |> halt()
    end
  end

  # payment arrived, get order and process package delivery !
  post "/order/:orderid/payment-callback" do
    require Logger

    {:ok,bin,conn} = read_body(conn)
    %{"transaction_id"=> transaction_id} = Poison.decode!(bin)

    {:ok, pid} = OrderTransactor.start(orderid)
    case GenServer.call(pid, {:payment, %{"transaction_id"=> transaction_id}}, 20_000) do
      {:ok, _} ->
        Logger.info("[Payment] " <> orderid <> " is paid")
        conn |> send_resp(200,"") |> halt()
      err ->
        Logger.error("[Payment] Error #{inspect err}")
        conn |> send_resp(500,"") |> halt()
    end
  end
end

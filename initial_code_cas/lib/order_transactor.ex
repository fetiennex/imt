defmodule OrderTransactor do
  use GenServer
  require Logger
  @retries 1

  def start(order_id, order \\ nil) do
    case GenServer.start_link(__MODULE__, {order_id, order}, name: :"#{order_id}_transactor") do
      {:ok, p} ->
      #  Logger.info("[Transactor] New")
        {:ok, p}
      {:error, {:already_started, p}} ->
      #  Logger.info("[Transactor] Already started")
        {:ok, p}
      err -> err
    end
  end

  def init({order_id, new_order}) do
    order = MicroDb.HashTable.get("orders", order_id) || nil #get retourne nil s'il n'y arrive pas, utilité de cette ligne ? de plus nil est toujours false et A || false = A
    case order do
      nil ->
        #IO.puts("init passed")
        {:ok, %{id: order_id, order: nil}, {:continue, {:new, new_order}}}
      _ ->
        #IO.puts("init passed")
        {:ok, %{id: order_id, order: order}, {:continue, {:new, nil}}}
    end
    #{:ok, %{id: order_id, order: order}, {:continue, {:new, new_order}}}
  end
  #et si order existe ? On appele continue avec new_order et un state != nil, ça fait une erreur. Cela arrive quand le superviseur relance le genserver avec son state précedent.

  def handle_continue({:new, nil}, state) do
    #IO.puts("handle_continue (nil) passed")
    {:noreply, state}
  end

  def handle_continue({:new, order}, %{id: _order_id, order: nil}) do # when not is_nil(order) do # <- cela ne semble rien changer
    selected_store = Enum.find(1..200, fn store_id->
      Enum.all?(order["products"],fn %{"id"=>prod_id,"quantity"=>q}->
        case MicroDb.HashTable.get("stocks",{store_id,prod_id}) do
          nil-> false
          store_q when store_q >= q-> true
          _-> false
        end
      end)
    end)
    order = Map.put(order,"store_id",selected_store)
    {:ok,{{_,200,_},_,_}} = :httpc.request(:post,{'http://localhost:9091/order/new',[],'application/json',Poison.encode!(order)},[],[])
    MicroDb.HashTable.put("orders",order["id"],order)
    {:noreply, %{id: order["id"], order: order}}

  end

  def handle_call({:payment, %{"transaction_id" => transaction_id}, }, _from ,%{id: id, order: order}) when not is_nil(order) do
    httpc_request(id,order,transaction_id,0)
  end

  def httpc_request(id,order,transaction_id, retry) do
    {:ok,{{_,code,_},_,_}} = :httpc.request(:post,{'http://localhost:9091/order/process_delivery',[],'application/json',Poison.encode!(order)},[],[])
    #Logger.info(["[Transactor] transactor_",id, "try=",retry, " code=",code])
    case code do
      code when code < 300 ->
        order = Map.put(order,"transaction_id",transaction_id)
        MicroDb.HashTable.put("orders",id,order)
        {:stop, :normal, {:ok, order}, %{id: id, order: order}}

      code when code > 500 ->
        if retry >= @retries do
        #  Logger.info(["[Transactor] transactor_",id," FAILED"])
          {:stop, code , {:error,code}, %{id: id, order: order}}
        else
          httpc_request(id,order,transaction_id,retry+1)
        end


      _ -> {:stop, code , {:error,code}, %{id: id, order: order}}

    end

  end

end

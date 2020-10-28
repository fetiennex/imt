defmodule OrderTransactor do
  use GenServer

  def start(order_id, order \\ nil) do
    case GenServer.start_link(__MODULE__, {order_id, order}, name: :"#{order_id}_transactor") do
      {:ok, p} -> {:ok, p}
      {:error, {:already_started, p}} -> {:ok, p}
      err -> err
    end
  end

  def init({order_id, new_order}) do
    order = MicroDb.HashTable.get("orders", order_id) || nil #get retourne nil s'il n'y arrive pas, utilité de cette ligne ? de plus nil est toujours false et A || false = A
    case order do
      nil -> {:ok, %{id: order_id, order: nil}, {:continue, {:new, new_order}}}
      _ -> {:ok, %{id: order_id, order: order}, {:continue, {:new, nil}}}
    end
    #{:ok, %{id: order_id, order: order}, {:continue, {:new, new_order}}}
  end
  #et si order existe ? On appele continue avec new_order et un state != nil, ça fait une erreur. Cela arrive quand le superviseur relance le genserver avec son state précedent.

  def handle_continue({:new, nil}, state) do
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

  def handle_call({:payment, %{"transaction_id" => transaction_id}}, _from ,%{id: id, order: order}) when not is_nil(order) do
    {:ok,{{_,200,_},_,_}} = :httpc.request(:post,{'http://localhost:9091/order/process_delivery',[],'application/json',Poison.encode!(order)},[],[])
    order = Map.put(order,"transaction_id",transaction_id)
    MicroDb.HashTable.put("orders",id,order)
    {:stop, :normal, {:ok, order}, %{id: id, order: order}}
  end
end

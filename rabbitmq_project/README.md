# RabbitmqProject

Project simulating a database of items being ordered and resupplied, triggering notifications when the stock reaches certain quantities, aiming at showing the use of RabbitMQ.
The application is separated in two nodes:
* Server node, launched with iex -S mix : manages the Orders supervision tree, the Agents supervision tree and the Resupplier process. Is in charge of the database.
* Clients node, launched with iex --sname client -S mix : manages the Clients, processes connecting to the rabbitmq exchange and receiving notifications.

## Installation

docker run -d --hostname my-rabbit --name some-rabbit rabbitmq:3

mix deps.get

to run the server node : iex -S mix

to run the client node : iex --sname client -S mix

## Configuration

To modify parameters, you have to edit the json file config.json . You will be able to change the stress on the database (add orders, add resupply quantity) and manage the clients (generate more clients, with more or less subscription and thresholds).

    "resuply_add_number": Quantity of items to add per resupply
    "resupply_sleep_time": Time the resupplier sleeps between resupplies
    "order_num_orders": Quantity of orders to be generated
    "order_max_pids": Max number of different items an order can buy per action.
    "order_max_items": Max quantity of items to be bought per item,
    "order_sleep_time": Time the order sleeps before buying again
    "agent_min_before_resupply": Thresholds of items at which an agent asks for a resupply
    "rabbitmq_options": Host and port of rabbitmq (configured for docker)
    "rabbitmq_thresholds": Thresholds for notifications
    "rabbitmq_max_keys_sub": Number max of items a generated client can subscrine to
    "rabbitmq_max_thre_sub": Number max of thresholds a generated client can have per item
    "rabbitmq_rand_clients_num": Number of clients to generate randomly
    
To test clients, you can edit clients.json and create custom clients. You can set the number of generated clients to 0 if you want no other client.
You can also change the starting database of products in products.json.

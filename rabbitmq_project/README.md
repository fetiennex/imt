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

To modify parameters, for now you have to efit the file lib/constants.ex . You will be able to change the stress on the database (add orders, add resupply quantity) and manage the clients (generate more clients, with more or less subscription and thresholds).

Soon : edit a json file, + clients.json for creating custom clients


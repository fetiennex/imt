defmodule MyConfig do
  @config_key :my_config

  def load(file_path) do
    cfg = file_path
    |> File.read!
    |> Poison.decode!
    :persistent_term.put(@config_key, cfg)
  end

  def get(param), do: :persistent_term.get(@config_key) |> Map.get(param)

  def get_rabbit_options do
    list = :persistent_term.get(@config_key) |> Map.get("rabbitmq_options")
    [host: Enum.at(list,0), port: Enum.at(list,1)]
  end
end

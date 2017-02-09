defmodule UdpClient do
    use Application
    require Logger

    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        children = [
            supervisor(UdpClient.Collector.Supervisor, []),
            supervisor(UdpClient.Worker.Supervisor, []),
        ]

        opts = [strategy: :one_for_one, name: UdpClient.Supervisor]
        Supervisor.start_link(children, opts)
    end

    def start_client(client_id, address \\ "127.0.0.1", port \\ Application.get_env(:udp_client, :udp_port)) do
        UdpClient.Worker.Supervisor.start_child(address, port, client_id)
    end

    def start_clients(nb_clients, address \\ "127.0.0.1", port \\ Application.get_env(:udp_client, :udp_port)) do
        Enum.each(1..nb_clients, fn(client_id) ->
            {:ok, client} = start_client(client_id, address, port)
            initial_delay = Enum.random(50..300)
            UdpClient.Worker.start_ping(client, initial_delay)
        end)
    end

end

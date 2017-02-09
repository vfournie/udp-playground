defmodule UdpClient.Worker.Supervisor do
    use Supervisor

    def start_child(address, port, client_id) do
        Supervisor.start_child(__MODULE__, [[address, port, client_id]])
    end

    def start_link() do
        Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    def init(:ok) do
        children = [
            worker(UdpClient.Worker, [], restart: :temporary)
        ]

        supervise(children, strategy: :simple_one_for_one)
    end

end

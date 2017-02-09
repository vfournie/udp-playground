defmodule UdpServer do
    use Application
    require Logger

    def start(_type, _args) do
        import Supervisor.Spec, warn: false

        children = [
            supervisor(UdpServer.Collector.Supervisor, []),
		    :poolboy.child_spec(udp_pool_name(), udp_poolboy_config(), []),
            worker(UdpServer.Worker, []),
        ]

        opts = [strategy: :one_for_one, name: UdpServer.Supervisor]
        Supervisor.start_link(children, opts)
    end

	def udp_pool_name() do
		:udp_pool
	end

    defp udp_poolboy_config() do
	    [
			{:name, {:local, udp_pool_name()}},
	      	{:worker_module, UdpServer.PacketWorker},
            # Will start with a pool of ':size' workers
	      	{:size, 100},
            # If all ':size' workers are busy, will create another ':max_overflow' workers
            #  for a total of (':size' + ':max_overflow')
	      	{:max_overflow, 400}
		]
	end

end

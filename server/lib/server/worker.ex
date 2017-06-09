defmodule UdpServer.Worker do
    use GenServer
    require Logger

    @so_sndbuf_size 2097152 # 2 MB
    @so_rcvbuf_size 2097152 # 2 MB

    defmodule State do
        defstruct [
            socket: nil,
        ]
    end

    ## Client API

	def start_link() do
		GenServer.start_link(__MODULE__, :ok)
	end

    ## Server Callbacks

	def init(:ok) do
        port = Application.get_env(:udp_server, :udp_port)
		opts = [:binary, reuseaddr: true, recbuf: @so_rcvbuf_size, sndbuf: @so_sndbuf_size]

        with {:ok, socket} <- :gen_udp.open(port, opts)
        do
            Logger.info("UDP server listening on port #{inspect port}")
            {:ok, %State{socket: socket}}
        else error ->
            Logger.info("UDP server failed to open socket (#{inspect error})")
            error
        end
	end

	def handle_info({:udp, socket, addr, port, data}, state) do
        process_packet(socket, addr, port, data)

		{:noreply, state}
	end

    def handle_info(_any, state) do
        {:noreply, state}
    end

    def terminate(_reason, %State{socket: socket} = _state) do
        :gen_udp.close(socket)
    end

    ## Private

    defp process_packet(socket, addr, port, data) do
        begin_time = System.monotonic_time()

        Task.async(fn() ->
            :poolboy.transaction(
                UdpServer.udp_pool_name(),
                fn(pid) ->
                    UdpServer.PacketWorker.process_packet(pid, socket, addr, port, data)

                    end_time = System.monotonic_time()
                    UdpServer.Collector.recv_packet(addr, port, (end_time - begin_time))
                end
            )
		    end
		)
    end

end

defmodule UdpServer.PacketWorker do
    use GenServer
    require Logger
    @behaviour :poolboy_worker

    ## Client API

    def start_link(opts) do
      	GenServer.start_link(__MODULE__, [], opts)
    end

    def process_packet(pid, socket, addr, port, data) do
        GenServer.call(pid, {:process, socket, addr, port, data})
    end

    ## Server Callbacks

    def init(_) do
		{:ok, %{}}
    end

    def handle_call({:process, socket, addr, port, data}, _from, state) do
        # Send back the packet
        :gen_udp.send(socket, addr, port, data)

		{:reply, :ok, state}
    end

end

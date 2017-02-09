defmodule UdpClient.Worker do
    use GenServer
    require Logger

    @so_sndbuf_size 2097152 # 2 MB
    @so_rcvbuf_size 2097152 # 2 MB

    defmodule State do
        defstruct [
            socket: nil,
            address: nil,
            port: nil,
            client_id: nil,
            timer_pid: nil,
        ]
    end

    ## Client API

    def start_link([_address, _port, _client_id] = args) do
		GenServer.start_link(__MODULE__, args)
	end

    def start_ping(pid, initial_delay \\ 0) do
        GenServer.call(pid, {:start_ping, initial_delay})
    end

    def stop_ping(pid) do
        GenServer.call(pid, :stop_ping)
    end

    def stop(pid) do
        GenServer.stop(pid)
    end

    ## Server Callbacks

	def init([address, port, client_id]) do
		opts = [:binary, reuseaddr: true, recbuf: @so_rcvbuf_size, sndbuf: @so_sndbuf_size]
        address = String.to_charlist(address)

		with {:ok, socket} <- :gen_udp.open(0, opts),
             {:ok, timer_pid} <- UdpClient.Worker.SendTimer.start_link([socket, address, port, client_id])
        do
            {:ok, %State{
                socket: socket,
                address: address,
                port: port,
                timer_pid: timer_pid,
                client_id: client_id,
            }}
        else error ->
            Logger.info("UDP client failed to connect (#{inspect error})")
            error
        end
	end

    def handle_call({:start_ping, initial_delay}, _from, %State{timer_pid: timer_pid} = state) do
        UdpClient.Worker.SendTimer.start_timer(timer_pid, initial_delay)

        {:reply, :ok, state}
    end

    def handle_call(:stop_ping, _from, %State{timer_pid: timer_pid} = state) do
        UdpClient.Worker.SendTimer.stop_timer(timer_pid)

        {:reply, :ok, state}
    end

	def handle_info({:udp, _socket, _ip, _port, data}, %State{client_id: client_id} = state) do
        # Update recv counter
        recv_counter = {:recv, client_id}
        UdpClient.Collector.inc_counter(recv_counter)

        process_packet(data, client_id)

        {:noreply, state}
    end

    def handle_info(_any, state) do
        {:noreply, state}
    end

    def terminate(_reason, %State{socket: socket} = _state) do
        :gen_udp.close(socket)
    end

    # Private

    def process_packet(binary, client_id)

    def process_packet(<<
                        10 :: size(16),
                        time :: signed-integer-size(64),
                       >>,
                       client_id) do
        curr_time = System.monotonic_time(:milliseconds)
        delta = curr_time - time

        :ets.insert_new(:udp_stats, {{:pong, client_id, time}, delta})
    end

    def process_packet(_, _client_id) do
        :ok
    end

end

defmodule UdpClient.Worker.SendTimer do
    use GenServer
    require Logger

    @period         200   # Period between executions (in ms)

    defmodule State do
        defstruct [
            socket: nil,
            address: nil,
            port: nil,
            client_id: nil,
            timer: nil,
        ]
    end

    ## Client API

    def start_link([_socket, _address, _port, _client_id] = args) do
        GenServer.start_link(__MODULE__, args)
	end

    def start_timer(pid, initial_delay) do
        GenServer.call(pid, {:start_timer, initial_delay})
    end

    def stop_timer(pid) do
        GenServer.call(pid, :stop_timer)
    end

    ## Server Callbacks

	def init([socket, address, port, client_id]) do
        {:ok,  %State{
            socket: socket,
            address: address,
            port: port,
            client_id: client_id
        }}
    end

    def handle_call({:start_timer, initial_delay}, _from, state) do
        timer = Process.send_after(self(), :ping, initial_delay)

        {:reply, :ok, %State{state | timer: timer}}
    end

    def handle_call(:stop_timer, _from, %State{timer: timer} = state) do
        cancel_timer(timer)

        {:reply, :ok, %State{state | timer: nil}}
    end

    def handle_info(:ping, %State{socket: socket, address: address, port: port, client_id: client_id} = state) do
        # Send ping
        monotonic_time = System.monotonic_time(:milliseconds)
        packet = <<
            10 :: size(16),
            monotonic_time :: signed-integer-size(64),
        >>
        :ok = :gen_udp.send(socket, address, port, packet)

        # Update send counter
        send_counter = {:send, client_id}
        UdpClient.Collector.inc_counter(send_counter)

        # Start the timer again
        timer = Process.send_after(self(), :ping, @period)

        {:noreply, %State{state | timer: timer}}
    end

    def handle_info(_any, state) do
        {:noreply, state}        
    end

    ## Pivate

    defp cancel_timer(timer)
    defp cancel_timer(nil),     do: :ok
    defp cancel_timer(timer),   do: Process.cancel_timer(timer)

end

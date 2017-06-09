defmodule UdpServer.Collector do
    use GenServer

    defmodule State do
        @type t :: %__MODULE__{}
        defstruct []
    end

    ## Client API

    @spec start_link :: GenServer.on_start
	def start_link do
		GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
	end

    @spec recv_packet(:inet.ip_address, :inet.port_number, integer) :: no_return
    def recv_packet(addr, port, process_time) do
        GenServer.cast(__MODULE__, {:recv_packet, addr, port, process_time})
    end

    ## Server Callbacks

    @spec init(:ok) :: {:ok, State.t}
    def init(:ok) do
        {:ok, %State{}}
    end

    @spec handle_cast(term, term) :: {:noreply, term} | {:stop, term, term}
    def handle_cast(request, state)

    def handle_cast({:recv_packet, addr, port, process_time}, state) do
        true = :ets.insert(:udp_stats, {{addr, port}, process_time})

        {:noreply, state}
    end

    @spec handle_info(term, term) :: {:noreply, term}
    def handle_info(_msg, state) do
        {:noreply, state}
    end

end

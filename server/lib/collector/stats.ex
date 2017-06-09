defmodule UdpServer.UdpStats do
    use GenServer
    require Logger

    @initial_delay  1_000   # Delay becore first execution (in ms)
    @period         5_000   # Period between executions (in ms)

    defmodule State do
        @type t :: %__MODULE__{}
        defstruct []
    end

    ## Client API

    @spec start_link :: GenServer.on_start
	def start_link do
		GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
	end

    ## Server Callbacks

    @spec init(:ok) :: {:ok, State.t}
    def init(:ok) do
        Process.send_after(self(), :dump, @initial_delay)

        {:ok, %State{}}
    end

    @spec handle_info(term, term) :: {:noreply, term}
    def handle_info(msg, state)

    def handle_info(:dump, state) do
        display_stats()

        # Start the timer again
        Process.send_after(self(), :dump, @period)

        {:noreply, state}
    end

    def handle_info(_msg, state) do
        {:noreply, state}
    end

    ## Private

    defp display_stats do
        process_times = :ets.select(:udp_stats, [{{{:"_", :"_"}, :"$1"}, [], [:"$1"]}])

        count = Enum.count(process_times)

        {min, max, avg} =
            case count > 0 do
                true ->
                    min = Enum.min(process_times)
                    max = Enum.max(process_times)
                    avg = Enum.sum(process_times) / count

                    {
                        min |> :erlang.convert_time_unit(:native, :microsecond),
                        max |> :erlang.convert_time_unit(:native, :microsecond),
                        avg |> trunc |> :erlang.convert_time_unit(:native, :microsecond),
                    }
                _ ->
                    {0, 0, 0}
            end

        pool_status = :poolboy.status(UdpServer.udp_pool_name())
        Logger.warn("UDP.stats - rcv: #{count} - process times min: #{min} μs - max: #{max} μs - avg: #{avg} μs\t\tPool status: #{inspect pool_status}")
    end

end

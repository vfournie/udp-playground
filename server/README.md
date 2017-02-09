# UDP Server

UDP server OTP app.  
The app will open an UDP socket on a configurable (see [config.exs](./config/config.exs)) port and wait for connections.  
Upon connection, it will echo back any packet sent.  

## Running

Prerequesites:
- Elixir 1.3.X
- Erlang 1.9.X

### Dependencies

If it's a fresh clone or updated branch, do:
```
> mix deps.get
```

### Run

To run the server:
```
> iex -S mix
```

To see the statistics, issue the following in the iex shell:
```
iex(1)> UdpServer.Collector.display_stats
```

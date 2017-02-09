defmodule UdpServer.Mixfile do
    use Mix.Project

    def project do
    [
        app: :udp_server,
        version: "0.1.0",
        elixir: "~> 1.3",
        build_embedded: Mix.env == :prod,
        start_permanent: Mix.env == :prod,
        deps: deps()
    ]
    end

    def application do
    [
        applications: [:logger, :poolboy],
        mod: {UdpServer, []}
    ]
    end

    defp deps do
    [
	    {:poolboy, "~> 1.5"},
    ]
    end

end

defmodule UdpClient.Mixfile do
    use Mix.Project

    def project do
    [
        app: :udp_client,
        version: "0.1.0",
        elixir: "~> 1.3",
        build_embedded: Mix.env == :prod,
        start_permanent: Mix.env == :prod,
        deps: deps()
    ]
    end

    def application do
    [
        applications: [:logger],
        mod: {UdpClient, []}
    ]
    end

    defp deps do
    [
    ]
    end

end

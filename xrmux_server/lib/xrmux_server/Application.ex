# ********************************************************************************************************
# Application
#
# By roy.davies@auckland.ac.nz
#
# The main supervising Application that starts everything else up
# ********************************************************************************************************
defmodule XrmuxServer.Application do
    # See https://hexdocs.pm/elixir/Application.html
    # for more information on OTP Applications
    @moduledoc false

    use Application

    # ----------------------------------------------------------------------------------------------------
    # The first piece of code to be run which sets up the HubSupervisor
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def start(_type, _args) do
        :observer.start()
        start_webserver()

        IO.puts("Application Started")

        children = [
            %{
                id: HubSupervisor,
                start: { XrmuxServer.HubSupervisor, :start_link, [] },
                type: :supervisor
            }
        ]

        opts = [
            strategy: :one_for_one
        ]

        Supervisor.start_link(children, opts)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Start the webserver and process to handle websockets
    # ----------------------------------------------------------------------------------------------------
    def start_webserver() do
        dispatch = :cowboy_router.compile([
            {:_, [
                {"/",           XrmuxServer.InfoPage,           []},
                {"/comms",      XrmuxServer.WebsocketHandler,   []}
            ]}
        ])

        :cowboy.start_clear(:http,
            [{:port, 8810}],
            %{:env => %{:dispatch => dispatch}}
        )
    end
    # ----------------------------------------------------------------------------------------------------
end

defmodule XrmuxServer.AppSupervisor do
    use DynamicSupervisor

    # ----------------------------------------------------------------------------------------------------
    # Start the Hub Supervisor - called by the main application process
    # ----------------------------------------------------------------------------------------------------
    def start_link() do
        IO.puts "App Supervisor Started"
        # id = spawn_link XrmuxServer.HubSupervisor, :loop, [%{}]
        # Process.register id, :HubComms
        DynamicSupervisor.start_link(__MODULE__, :ok, name: :AppSup)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Initialisation for the Entities coming off the Hub
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def init(:ok) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end
    # ----------------------------------------------------------------------------------------------------

end

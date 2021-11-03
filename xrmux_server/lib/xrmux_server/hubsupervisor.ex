# ********************************************************************************************************
# HubSupervisor
#
# By roy.davies@auckland.ac.nz
#
# A process that supervises the Hub process
# ********************************************************************************************************
defmodule XrmuxServer.HubSupervisor do
    use DynamicSupervisor

    # ----------------------------------------------------------------------------------------------------
    # Start the Hub Supervisor - called by the main application process
    # ----------------------------------------------------------------------------------------------------
    def start_link() do
        IO.puts "Hub Started"
        # id = spawn_link XrmuxServer.HubSupervisor, :loop, [%{}]
        # Process.register id, :HubComms
        DynamicSupervisor.start_link(__MODULE__, :ok, name: :Hub)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Initialisation for the Apps coming off the Hub
    # ----------------------------------------------------------------------------------------------------
    def init(:ok) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Add an App if it doesn't already exist
    # ----------------------------------------------------------------------------------------------------
    def add_app(from, appname) do
        appname_atom = String.to_atom(appname)
        child_spec = %{id: Hello, start: {XrmuxServer.App, :start_link, [appname_atom]}}
        case DynamicSupervisor.start_child(:Hub, child_spec) do
            {:ok, _appid} ->
                IO.puts "Starting #{appname}"
                send :HubComms, {:add, appname_atom, from}
            _ ->
                IO.puts "#{appname} already started"
                send :HubComms, {:add, appname_atom, from}
        end
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Remove an App if it exists
    # ----------------------------------------------------------------------------------------------------
    def remove_app(from) do
        IO.puts "Removing #{inspect from}"
        send :HubComms, {:remove, from}
        # DynamicSupervisor.terminate_child(:Hub, pid)
    end
    # ----------------------------------------------------------------------------------------------------
end

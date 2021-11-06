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
    def add_app_and_send_message(from, appname_atom, message) do
        if ! Process.whereis(appname_atom) do
            IO.puts "Starting App"
            child_spec = %{id: App, start: {XrmuxServer.AppSupSup, :start_link, [from, appname_atom, message]}}
            DynamicSupervisor.start_child(:Hub, child_spec)
            [entity | rest] = message
            entity_atom = String.to_atom(entity)
            XrmuxServer.AppSupervisor.add_entity_and_send_message(from, appname_atom, entity_atom, rest)
        else
            IO.puts "App already running"
            send appname_atom, {:in, from, appname_atom, message}
        end
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Remove an App if it exists
    # ----------------------------------------------------------------------------------------------------
    def remove_app(from, appname_atom) do
        send appname_atom, {:remove, from}
        # IO.puts "Removing #{inspect from}"
        # send :HubComms, {:remove, from}
        # DynamicSupervisor.terminate_child(:Hub, pid)
    end
    # ----------------------------------------------------------------------------------------------------
end

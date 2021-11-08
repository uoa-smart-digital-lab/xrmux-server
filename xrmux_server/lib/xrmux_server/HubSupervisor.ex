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
    # Remove the given App from the tree - done once all the websockets are closed
    # ----------------------------------------------------------------------------------------------------
    def remove_app(appname_atom) do
        name = (appname_atom |> Atom.to_string()) <> "_sup_sup" |> String.to_atom()
        do_remove_app(Process.whereis(name))
    end
    def do_remove_app(nil) do end
    def do_remove_app(pid) do
        DynamicSupervisor.terminate_child(:Hub, pid)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Add an App if it doesn't already exist
    # ----------------------------------------------------------------------------------------------------
    def add_app_and_send_message(from, appname_atom, message) do
        if ! Process.whereis(appname_atom) do
            child_spec = %{id: App, start: {XrmuxServer.AppSupSup, :start_link, [from, appname_atom, message]}}
            DynamicSupervisor.start_child(:Hub, child_spec)
            start_entity(from, appname_atom, message)
        else
            send appname_atom, {:in, from, appname_atom, message}
        end
    end
    def start_entity(_, _, []) do
        :ok
    end
    def start_entity(from, appname_atom, message) do
        [entity | rest] = message
        entity_atom = String.to_atom(entity)
        XrmuxServer.AppSupervisor.add_entity_and_send_message(from, appname_atom, entity_atom, rest)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Remove an App if it exists
    # ----------------------------------------------------------------------------------------------------
    def remove_app(from, appname_atom) do
        send appname_atom, {:remove, from, appname_atom}
    end
    # ----------------------------------------------------------------------------------------------------
end

defmodule XrmuxServer.AppSupervisor do
    use DynamicSupervisor

    # ----------------------------------------------------------------------------------------------------
    # Start the Hub Supervisor - called by the main application process
    # ----------------------------------------------------------------------------------------------------
    def start_link(_from, appname_atom, _message) do
        IO.puts "App Supervisor Started"
        name = (appname_atom |> Atom.to_string()) <> "_sup" |> String.to_atom()
        DynamicSupervisor.start_link(__MODULE__, :ok, name: name)
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



    # ----------------------------------------------------------------------------------------------------
    # Add an Entity if it doesn't already exist and / or send a message to it
    # ----------------------------------------------------------------------------------------------------
    def add_entity_and_send_message(from, appname_atom, entity_atom, message) do
        if ! Process.whereis(entity_atom) do
            IO.puts "Starting Entity"
            name = (appname_atom |> Atom.to_string()) <> "_sup" |> String.to_atom()
            child_spec = %{id: Entity, start: {XrmuxServer.Entity, :start_link, [from, appname_atom, entity_atom, message]}}
            DynamicSupervisor.start_child(name, child_spec)
        else
            IO.puts "Entity already running"
            send entity_atom, {from, appname_atom, entity_atom, message}
        end
    end
    # ----------------------------------------------------------------------------------------------------

end

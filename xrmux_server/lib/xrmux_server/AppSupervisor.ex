defmodule XrmuxServer.AppSupervisor do
    use DynamicSupervisor

    # ----------------------------------------------------------------------------------------------------
    # Start the Hub Supervisor - called by the main application process
    # ----------------------------------------------------------------------------------------------------
    def start_link(from, appname_atom, _message) do
        IO.puts "App Supervisor Started"
        name = (appname_atom |> Atom.to_string()) <> "_sup" |> String.to_atom()
        DynamicSupervisor.start_link(__MODULE__, :ok, name: name)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Initialisation for the Entities coming off the Hub
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def init(_) do
        DynamicSupervisor.init(strategy: :one_for_one)
    end
    # ----------------------------------------------------------------------------------------------------

end

# ********************************************************************************************************
# AppSupSup
#
# By roy.davies@auckland.ac.nz
#
# The main supervisor for the tree of processes related to each App
# ********************************************************************************************************
defmodule XrmuxServer.AppSupSup do
    use Supervisor

    # ----------------------------------------------------------------------------------------------------
    # Start the process
    # ----------------------------------------------------------------------------------------------------
    def start_link(from, appname_atom, message) do
        name = (appname_atom |> Atom.to_string()) <> "_sup_sup" |> String.to_atom()
        Supervisor.start_link(__MODULE__, [from, appname_atom, message], name: name)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Initialise the process
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def init(params) do
        children = [
            %{
                id: AppSupervisor,
                start: { XrmuxServer.AppSupervisor, :start_link, params },
                type: :supervisor
            },

            %{
                id: AppComms,
                start: { XrmuxServer.AppComms, :start_link, params },
                type: :worker
            }
        ]

        opts = [
            strategy: :one_for_one
        ]

        Supervisor.init(children, opts)
    end
    # ----------------------------------------------------------------------------------------------------
end

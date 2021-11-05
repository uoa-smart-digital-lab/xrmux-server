defmodule XrmuxServer.AppSupSup do
    use Supervisor

    def start_link(from, appname_atom, message) do
        name = (appname_atom |> Atom.to_string()) <> "_sup_sup" |> String.to_atom()
        IO.puts "AppSupSup #{inspect { from, appname_atom, message }}"
        Supervisor.start_link(__MODULE__, [from, appname_atom, message], name: name)
    end

    @impl true
    def init(params) do
        IO.puts "Init #{inspect params}"
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
end

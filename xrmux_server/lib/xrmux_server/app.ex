# ********************************************************************************************************
# App
#
# By roy.davies@auckland.ac.nz
#
# Each MR App gets its own process which then supervises all the individual processes for each object
# ********************************************************************************************************
defmodule XrmuxServer.App do
    use DynamicSupervisor

    def start_link(app_name) do
        DynamicSupervisor.start_link(__MODULE__, :ok, name: app_name)
    end

    def init(:ok) do
        IO.puts "App Started"
        DynamicSupervisor.init(strategy: :one_for_one)
    end
end

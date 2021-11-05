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

    @impl true
    def init(:ok) do
        IO.puts "App Started"
        DynamicSupervisor.init(strategy: :one_for_one)
    end

    @impl true
    def handle_info({from, data}, _state) do
        IO.puts "Received #{inspect data} from #{inspect data}"
    end

    @impl true
    def handle_call(_, _, _) do
        IO.puts "call"
        {:reply, []}
    end

    @impl true
    def handle_cast(_, _) do
        IO.puts "cast"
        {:noreply, []}
    end

    # @impl true
    # def handle_cast({:push, element}, state) do
    #     {:noreply, [element | state]}
    # end
end

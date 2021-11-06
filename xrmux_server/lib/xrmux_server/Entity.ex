defmodule XrmuxServer.Entity do
    use GenServer

    # ----------------------------------------------------------------------------------------------------
    # ----------------------------------------------------------------------------------------------------
    def start_link(from, appname_atom, entity_atom, message) do
        IO.puts "Starting Entity #{inspect entity_atom}"
        GenServer.start_link(__MODULE__, [from, appname_atom, entity_atom, message])
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def init([from, appname_atom, entity_atom, message]) do
        IO.puts "Initing Entity #{inspect entity_atom}"
        Process.register self(), entity_atom
        interpret_message(from, appname_atom, entity_atom, message)
        {:ok, []}
    end
    # ----------------------------------------------------------------------------------------------------


    # ----------------------------------------------------------------------------------------------------
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def handle_info({from, appname_atom, entity_atom, message}, state) do
        interpret_message(from, appname_atom, entity_atom, message)
        {:noreply, state}
    end

    def interpret_message(from, appname_atom, entity_atom, message) do
        IO.puts "Entity #{inspect entity_atom} Message #{inspect message} for #{inspect appname_atom}"
        send appname_atom, {:out, from, appname_atom, [ entity_atom | message ]}
    end
    # ----------------------------------------------------------------------------------------------------
end

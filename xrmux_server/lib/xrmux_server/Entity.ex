# ********************************************************************************************************
# Entity
#
# By roy.davies@auckland.ac.nz
#
# A process that manages the communications for each entity of each app
# ********************************************************************************************************
defmodule XrmuxServer.Entity do
    use GenServer

    # ----------------------------------------------------------------------------------------------------
    # Start the entity process
    # ----------------------------------------------------------------------------------------------------
    def start_link(from, appname_atom, entity_atom, message) do
        GenServer.start_link(__MODULE__, [from, appname_atom, entity_atom, message])
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Initialise the entity process
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def init([from, appname_atom, entity_atom, message]) do
        Process.register self(), entity_atom
        interpret_message(from, appname_atom, entity_atom, message)
        {:ok, []}
    end
    # ----------------------------------------------------------------------------------------------------


    # ----------------------------------------------------------------------------------------------------
    # Handle the messages coming to the Entity, and send them back out again
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def handle_info({from, appname_atom, entity_atom, message}, state) do
        interpret_message(from, appname_atom, entity_atom, message)
        {:noreply, state}
    end

    def interpret_message(from, appname_atom, entity_atom, message) do
        send appname_atom, {:out, from, appname_atom, [ entity_atom | message ]}
    end
    # ----------------------------------------------------------------------------------------------------
end

defmodule XrmuxServer.AppComms do
    use GenServer

    # ----------------------------------------------------------------------------------------------------
    # ----------------------------------------------------------------------------------------------------
    def start_link(from, appname_atom, message) do
        IO.puts "Starting #{inspect appname_atom}"
        GenServer.start_link(__MODULE__, [from, appname_atom, message])
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def init([from, appname_atom, _message]) do
        IO.puts "Initing #{inspect appname_atom}"
        Process.register self(), appname_atom
        {:ok, MapSet.new([from])}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Add or remove a websocket PID from the list
    # ----------------------------------------------------------------------------------------------------
    def add_pid_to_list(state, pid) do
        state |> MapSet.put(pid)
    end

    def remove_pid_from_list(state, pid) do
        state |> MapSet.delete(pid)
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Message from a device client coming in and going out
    # ----------------------------------------------------------------------------------------------------
    @impl true
    def handle_info({:in, from, appname_atom, message}, state) do
        IO.puts "App Message #{inspect message}"
        IO.puts "App State #{inspect state}"

        newstate = add_pid_to_list(state, from)

        [entity | rest] = message
        entity_atom = String.to_atom(entity)
        XrmuxServer.AppSupervisor.add_entity_and_send_message(from, appname_atom, entity_atom, rest)

        {:noreply, newstate}
    end

    def handle_info({:out, from, appname_atom, message}, state) do
        send_message_to_all(state, appname_atom, message, from)
        {:noreply, state}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # ----------------------------------------------------------------------------------------------------
    def handle_info({:remove, from}, state) do
        newstate = remove_pid_from_list(state, from)
        {:noreply, newstate}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Send a message to all the pids (ie websockets) in the set except the one it came from
    # ----------------------------------------------------------------------------------------------------
    def send_message_to_all(state, appname_atom, message, except) do
        send_message(appname_atom, state |> MapSet.delete(except) |> MapSet.to_list(), message)
    end

    def send_message(_, [], _) do :ok end
    def send_message(appname_atom, [ws_pid | ws_pids], message) do
        IO.puts "Sending #{inspect message} to #{inspect ws_pid}"
        send(ws_pid, [appname_atom | message])
        send_message(appname_atom, ws_pids, message)
        :ok
    end
    # ----------------------------------------------------------------------------------------------------

end

defmodule XrmuxServer.HubComms do

    # ----------------------------------------------------------------------------------------------------
    # Start the receive loop
    # ----------------------------------------------------------------------------------------------------
    def start_link() do
        id = spawn_link XrmuxServer.HubComms, :loop, [%{}]
        Process.register id, :HubComms
        {:ok, id}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Maintain a state of which websocket processes are linked to this App
    # ----------------------------------------------------------------------------------------------------
    def loop(state) do
        receive do
            {:add, appname, pid} ->
                newstate = add_pid_to_appname(state, appname, pid)
                :erlang.display(newstate)
                loop(newstate)
            {:remove, pid} ->
                newstate = remove_pid_from_list(state, pid)
                :erlang.display(newstate)
                loop(newstate)
            {:send, appname, message, except} ->
                appname_atom = String.to_atom(appname)
                send_message_to_all(state, appname_atom, message, except)
                loop(state)
            other ->
                IO.puts("Uninterpreted message received #{inspect other}")
                loop(state)
        end
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Add or remove a websocket PID from the list under each Appname
    # ----------------------------------------------------------------------------------------------------
    def add_pid_to_appname(state, appname, pid) do
        case Map.fetch(state, appname) do
            {:ok, set_of_pids} ->
                state |> Map.put(appname, set_of_pids |> MapSet.put(pid))
            :error ->
                state |> Map.put(appname, MapSet.new([pid]))
        end
    end

    def remove_pid_from_list(state, pid) do
        case find_appname(state |> Map.to_list(), pid) do
            {:err} -> state
            {:ok, appname} ->
                case Map.fetch(state, appname) do
                    {:ok, set_of_pids} ->
                        state |> Map.put(appname, set_of_pids |> MapSet.delete(pid))
                    :error ->
                        state
                end
        end
    end

    def find_appnname([], _) do
        {:err}
    end
    def find_appname([{appname, pids} | tail], pid) do
        case MapSet.member?(pids, pid) do
            true -> {:ok, appname}
            _ -> find_appname(tail, pid)
        end
    end
    # ----------------------------------------------------------------------------------------------------


    # ----------------------------------------------------------------------------------------------------
    # Send a message to all the pids (ie websockets) in the set
    # ----------------------------------------------------------------------------------------------------
    def send_message_to_all(state, appname, message, except) do
        case Map.fetch(state, appname) do
            {:ok, set_of_pids} ->
                send_message(appname, set_of_pids |> MapSet.delete(except) |> MapSet.to_list(), message)
            _ -> :ok
        end
    end

    def send_message(_, [], _) do
        :ok
    end
    def send_message(appname, [head | tail], message) do
        IO.puts "Sending #{inspect message} to #{inspect head}"
        send(head, %{:'app-name' => appname, :data => message})
        send_message(appname, tail, message)
        :ok
    end
    # ----------------------------------------------------------------------------------------------------

end

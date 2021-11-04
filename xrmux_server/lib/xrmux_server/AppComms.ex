defmodule XrmuxServer.AppComms do
    use GenServer

    def start_link(appname_atom) do
        {:ok, pid} = GenServer.start_link(XrmuxServer.AppComms, [appname_atom])
        Process.register pid, appname_atom

        supid = spawn_link XrmuxServer.AppSupervisor, :start_link, []
        IO.puts "Sup ID #{inspect supid}"
        Process.register supid, (appname_atom |> Atom.to_string()) <> "_sup" |> String.to_atom()
    end

    @impl true
    def init(init_arg) do
        IO.puts "Arguments #{inspect init_arg}"
        {:ok, %{}}
    end

    @impl true
    def handle_info(message, state) do
        IO.puts "Message #{inspect message}"
        IO.puts "State #{inspect state}"
        {:noreply, state}
    end



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

    def find_appname([], _) do {:err} end
    def find_appname([{appname, pids} | tail], pid) do
        case MapSet.member?(pids, pid) do
            true -> {:ok, appname}
            _ -> find_appname(tail, pid)
        end
    end
    # ----------------------------------------------------------------------------------------------------


    # ----------------------------------------------------------------------------------------------------
    # Send a message to all the pids (ie websockets) in the set except the one sending it
    # ----------------------------------------------------------------------------------------------------
    def send_message_to_all(state, appname, message, except) do
        case Map.fetch(state, appname) do
            {:ok, set_of_pids} ->
                send_message(appname, set_of_pids |> MapSet.delete(except) |> MapSet.to_list(), message)
            _ -> :ok
        end
    end

    def send_message(_, [], _) do :ok end
    def send_message(appname, [head | tail], message) do
        IO.puts "Sending #{inspect message} to #{inspect head}"
        send(head, %{:appname => appname, :data => message})
        send_message(appname, tail, message)
        :ok
    end
    # ----------------------------------------------------------------------------------------------------

end

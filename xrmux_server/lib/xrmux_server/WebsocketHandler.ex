# ********************************************************************************************************
# WebsocketHandler
#
# By roy.davies@auckland.ac.nz
#
# Waits for connections from devices and starts adn manages the websocket connections
# ********************************************************************************************************
defmodule XrmuxServer.WebsocketHandler do
    @behaviour :cowboy_websocket


    # ----------------------------------------------------------------------------------------------------
    # Initialise the websocket link - is called each time a device initiates a websocket connection
    # ----------------------------------------------------------------------------------------------------
    def init(req0, _) do
        state = %{:appname => app_name(req0)}

        case :cowboy_req.parse_header("sec-websocket-protocol", req0) do
            :undefined ->
                {:cowboy_websocket, req0, state}
            subprotocols ->
                case :lists.keymember("mqtt", 1, subprotocols) do
                    true ->
                        req = :cowboy_req.set_resp_header("sec-websocket-protocol", "mqtt", req0)
                        {:cowboy_websocket, req, state};
                    false ->
                        req = :cowboy_req.reply(400, req0)
                        {:ok, req, state}
                end
        end
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Extract the app name from the headers, if given.
    # ----------------------------------------------------------------------------------------------------
    def app_name(%{:headers => %{"appname" => appname}}) do
        appname
    end
    def app_name(_) do
        ""
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # What to do when the websocket closes
    # ----------------------------------------------------------------------------------------------------
    def terminate(_reason, _req, _state) do
        XrmuxServer.HubSupervisor.remove_app(self())
        IO.puts "Websocket closed"
        :ok
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Once the connection is established, check and possibly start a node to manage the app communications
    # ----------------------------------------------------------------------------------------------------
    def websocket_init(state) do
        start_app(state)
        {:ok, state}
    end
    # ----------------------------------------------------------------------------------------------------
    def start_app(%{:appname => ""}) do
        IO.puts "Websocket opened"
    end
    def start_app(%{:appname => appname}) do
        XrmuxServer.HubSupervisor.add_app(self(), appname)
        IO.puts "Websocket opened and connected to #{appname}"
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Handle messages coming from XR devices and extract the content
    # ----------------------------------------------------------------------------------------------------
    def websocket_handle({:text, content}, state) do
        case JSON.decode(content) do
            { :ok, message } -> interpret_message(message, state)
            _ -> {:ok, state}
        end
    end
    def websocket_handle(_frame, state) do
        {:ok, state}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Interpret messages coming from the devices into actions
    # ----------------------------------------------------------------------------------------------------
    # def interpret_message(%{ "appname" => appname, "entity" => entity}, state) do
    #     IO.puts "Sending #{inspect data} to #{appname}"
    #     send :HubComms, {:send, appname, data, self()}
    #     {:ok, state}
    # end
    # def interpret_message(%{ "connect" => appname }, state) do
    #     XrmuxServer.HubSupervisor.add_app(self(), appname)
    #     IO.puts "Websocket opened and connected to #{appname}"
    #     {:ok, state}
    # end
    # def interpret_message(%{ "entity" => entityname }, state) do
    #     XrmuxServer.HubSupervisor.add_app(self(), appname)
    #     IO.puts "Websocket opened and connected to #{appname}"
    #     {:ok, state}
    # end
    def interpret_message(message, state) do
        case Map.to_list(message) do
            [{appname, rest}] ->
                appname_atom = String.to_atom(appname)
                IO.puts "Sending #{inspect rest} to #{appname_atom}"
                XrmuxServer.HubSupervisor.add_app_and_send_message(self(), appname_atom, rest)
                {:ok, state}
            _ ->
                {:err, state}
        end
    end
    def interpret_message(other, state) do
        IO.puts ("External message #{inspect other}")
        {:ok, state}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Handle messages coming from internally
    # ----------------------------------------------------------------------------------------------------
    def websocket_info(%{ :appname => appname, :data => data }, state) do
        the_message = case JSON.encode(%{ "appname" => appname, :data => data }) do
            {:ok, message} -> message
            _ -> "{\"err\":\"json\"}"
        end

        { [{:text, the_message}], state }
    end
    def websocket_info(other, state) do
        IO.puts ("Internal message #{inspect other}")
        {:ok, state}
    end
    # ----------------------------------------------------------------------------------------------------
end

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
    def terminate(_reason, _req, appname_atom) do
        XrmuxServer.HubSupervisor.remove_app(self(), appname_atom)
        :ok
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Once the connection is established, check and possibly start a node to manage the app communications
    # ----------------------------------------------------------------------------------------------------
    def websocket_init(state) do
        {:ok, state}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Handle messages coming from XR devices and extract the content
    # ----------------------------------------------------------------------------------------------------
    def websocket_handle({:text, content}, state) do
        case JSON.decode(content) do
            { :ok, message } -> interpret_message_from_device(message, state)
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
    def interpret_message_from_device(message, state) do
        [{command, info}] = Map.to_list(message)
        interpret_message(command, info, state)
    end

    def interpret_message("data", [], state) do {:err, state} end
    def interpret_message("data", [_], state) do {:err, state} end
    def interpret_message("data", [_, _], state) do {:err, state} end
    def interpret_message("data", [_, _, _], state) do {:err, state} end
    def interpret_message("data", [_, _, _, _], state) do {:err, state} end
    def interpret_message("data", [appname | rest], state) do
        appname_atom = String.to_atom(appname)
        XrmuxServer.HubSupervisor.add_app_and_send_message(self(), appname_atom, rest)
        {:ok, appname_atom}
    end

    def interpret_message("connect", [appname], state) do
      appname_atom = String.to_atom(appname)
      XrmuxServer.HubSupervisor.add_app_and_send_message(self(), appname_atom, [])
      {:ok, appname_atom}
    end
    # ----------------------------------------------------------------------------------------------------



    # ----------------------------------------------------------------------------------------------------
    # Handle messages coming from internally
    # ----------------------------------------------------------------------------------------------------
    def websocket_info(message, state) do
        the_message = case JSON.encode(message) do
            {:ok, message_json} -> message_json
            _ -> "{\"err\":\"json\"}"
        end

        { [{:text, the_message}], state }
    end
    # ----------------------------------------------------------------------------------------------------
end

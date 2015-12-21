module.exports =
class WebsocketFactory
  @createWithTerminalLogging: (uri, terminal) ->
    ws = new WebSocket(uri)
    terminal.write("Connecting to Learn...\r\n")

    ws.onmessage = (e) ->
      terminal.write(e.data)
    ws.onerror = ->
      terminal.write("Error: Could not establish a connection.")
    ws.onclose = ->
      terminal.write("Closed connection.")

    return ws

module.exports =
class WebsocketFactory
  @createWithTerminalLogging: (uri, terminal) ->
    ws = new WebSocket(uri)
    terminal.write("Connecting to Learn...\r\n")

    ws.onmessage = (e) ->
      terminal.write(e.data + "\r\n")
    ws.onerror = ->
      terminal.write("Error: Could not establish a connection.\r\n")
    ws.onclose = ->
      terminal.write("aClosed connection.\r\n")

    return ws

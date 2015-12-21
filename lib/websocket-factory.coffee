module.exports =
class WebsocketFactory
  @createWithTerminalLogging: (uri, terminal) ->
    ws = new WebSocket(uri)
    terminal.write("Connecting to Learn...")

    ws.onmessage = (e) ->
      terminal.write(e.data)
    ws.onerror = ->
      terminal.write("\r\nError: Could not establish a connection.")
    ws.onclose = ->
      terminal.write("\r\nClosed connection.")

    return ws

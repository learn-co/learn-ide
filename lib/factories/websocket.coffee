module.exports =
class WebsocketFactory
  @createWithTerminalLogging: (url, terminal) ->
    ws = new WebSocket(url)
    terminal.write("\x1b[1mConnecting to Learn...\x1b[m\r\n")

    ws.onmessage = (e) ->
      terminal.write(e.data)
    ws.onerror = ->
      terminal.write("\r\n\x1b[1mError:\x1b[m Could not establish a connection.\r\n")
    ws.onclose = ->
      terminal.write("\r\n\x1b[1mClosed connection.\x1b[m\r\n")

    return ws

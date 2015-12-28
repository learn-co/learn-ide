module.exports =
class WebsocketFactory
  @createWithTerminalLogging: (url, terminal) ->
    ws = new WebSocket(url)
    terminal.write("\x1b[1mConnecting to your Learn terminal...\x1b[m\r\n")

    ws.onmessage = (e) ->
      terminal.write(e.data)
    ws.onerror = ->
      terminal.write("\r\n\x1b[1mError:\x1b[m Could not establish a connection to terminal.\r\n")
    ws.onclose = ->
      terminal.write("\r\n\x1b[1mClosed connection to terminal.\x1b[m\r\n")
      
    return ws

  @createWithFSLogging: (url, terminal) ->
    ws = new WebSocket(url)

    ws.onmessage = (e) ->
      atom.notifications.addSuccess(e.data)
    ws.onerror = ->
      atom.notifications.addError("Could not establish a connection to the Learn filesystem!")
    ws.onclose = ->
      atom.notifications.addError("Closed connection to the Learn filesystem.")

    return ws

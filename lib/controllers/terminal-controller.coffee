module.exports =
class TerminalController
  constructor: (ws, terminal) ->
    if ws.connected
      terminal.write("Got connection")

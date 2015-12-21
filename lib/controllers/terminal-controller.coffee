module.exports =
class TerminalController
  constructor: (ws, terminal) ->
    terminal.on 'data', (data) ->
      ws.send data

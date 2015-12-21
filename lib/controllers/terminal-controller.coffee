module.exports =
class TerminalController
  constructor: (ws, terminal) ->
    terminal.write(" Connected!\r\n")

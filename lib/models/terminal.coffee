term = require 'term.js'

module.exports =
class Terminal
  constructor: (ws_url) ->
    @term = new term.Terminal(cols: 80, rows: 24, useStyle: no, screenKeys: no, scrollback: yes)
    @ws = new WebSocket(ws_url)

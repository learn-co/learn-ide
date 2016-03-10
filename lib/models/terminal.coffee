term = require 'term.js'

module.exports =
class Terminal
  constructor: (ws_url) ->
    @term = new term.Terminal(cols: 80, rows: 24, useStyle: no, screenKeys: no, scrollback: yes)
    @ws_url = ws_url
    @ws = new WebSocket(@ws_url)

  reset: (termView) ->
    @term.emit('data', "\r") # This doesn't work yet
    @ws.close()
    @ws = new WebSocket(@ws_url)
    @ws.onopen = =>
      termView.reset(@ws)

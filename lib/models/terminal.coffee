term = require 'term.js'

module.exports =
class Terminal
  constructor: (ws_url) ->
    @term = new term.Terminal(cols: 80, rows: 24, useStyle: no, screenKeys: no, scrollback: yes)
    @ws = new WebSocket(ws_url)

    @handleEvents()

  handleEvents: ->
    @term.on 'open', =>
      @term.write("\x1b[1m" + "Connecting to Learn terminal..." + "\x1b[m\r\n")
    @term.on 'data', (data) =>
      @ws.send(data)

    @ws.onmessage = (e) =>
      @term.write(e.data)
    @ws.onerror = =>
      @term.write("\x1b[1m" + "Error: " + "\x1b[m" + "Could not establish a connection to terminal." + "\r\n")
    @ws.onclose = =>
      @term.write("\x1b[1m" + "Closed connection to terminal." + "\x1b[m\r\n")

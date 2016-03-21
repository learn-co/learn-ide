term = require 'term.js'
ipc  = require 'ipc'
{EventEmitter} = require 'events'

module.exports =
class Terminal extends EventEmitter
  constructor: (ws_url) ->
    @term = new term.Terminal(cols: 80, rows: 24, useStyle: no, screenKeys: no, scrollback: yes)
    ipc.send 'register-new-terminal', ws_url
    this.setListeners()
    #@ws_url = ws_url
    #@ws = new WebSocket(@ws_url)

  setListeners: () ->
    ipc.on 'terminal-message', (message) =>
      this.emit 'terminal-message-received', message

  reset: (termView) ->
    @term.emit('data', "\r") # This doesn't work yet
    @ws.close()
    @ws = new WebSocket(@ws_url)
    @ws.onopen = =>
      termView.reset(@ws)

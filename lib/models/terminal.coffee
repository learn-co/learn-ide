term = require 'term.js'
ipc  = require 'ipc'
{EventEmitter} = require 'events'

module.exports =
class Terminal extends EventEmitter
  constructor: (ws_url) ->
    @term = new term.Terminal(cols: 80, rows: 24, useStyle: no, screenKeys: no, scrollback: yes)
    window.term = @term
    ipc.send 'register-new-terminal', ws_url
    this.setListeners()

  setListeners: () ->
    ipc.on 'terminal-message', (message) =>
      this.emit 'terminal-message-received', message

    ipc.on 'request-terminal-view', (request) =>
      ipc.send 'terminal-view-response',
        index: request.index
        html: document.getElementsByClassName('terminal')[0].innerHTML

    ipc.on 'update-terminal-view', (newHtml) =>
      parser = new DOMParser()
      doc = parser.parseFromString newHtml, "text/html"
      newNodes = doc.body.children

      existingNodes = document.getElementsByClassName('terminal')[0].childNodes

      lastNode = null
      for node in newNodes
        if node.innerText.match(/vm/)
          lastNode = node

      sanitizedText = lastNode.innerText.replace(/^\s+|\s+$/g, '')

      for char in sanitizedText
        this.emit 'raw-terminal-char-copy-received', char

      @term.showCursor()

  reset: (termView) ->
    @term.emit('data', "\r") # This doesn't work yet
    @ws.close()
    @ws = new WebSocket(@ws_url)
    @ws.onopen = =>
      termView.reset(@ws)

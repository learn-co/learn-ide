term = require 'term.js'
ipc  = require 'ipc'
{EventEmitter} = require 'events'

module.exports =
class Terminal extends EventEmitter
  constructor: (ws_url) ->
    @term = new term.Terminal(cols: 80, rows: 18, useStyle: no, screenKeys: no, scrollback: yes)
    window.term = @term
    ipc.send 'register-new-terminal', ws_url
    this.setListeners()

  updateConnectionState: (state) ->
    if state == 'closed'
      this.emit 'terminal-session-closed'
    else
      this.emit 'terminal-session-opened'

  setListeners: () ->
    ipc.on 'terminal-message', (message) =>
      this.emit 'terminal-message-received', message

    ipc.on 'request-terminal-view', (request) =>
      ipc.send 'terminal-view-response',
        index: request.index
        html: document.getElementsByClassName('terminal')[0].innerHTML

    ipc.on 'connection-state', (state) =>
      @updateConnectionState(state)

    ipc.on 'update-terminal-view', (newHtml) =>
      parser = new DOMParser()
      doc = parser.parseFromString newHtml, "text/html"
      newNodes = doc.body.children

      existingNodes = document.getElementsByClassName('terminal')[0].childNodes

      lastNode = null
      for node in newNodes
        if node.innerText.match(/\S/)
          lastNode = node

      if lastNode
        sanitizedText = lastNode.innerText.replace(/^\s+|\s+$/g, '')

      if sanitizedText
        for char in sanitizedText
          this.emit 'raw-terminal-char-copy-received', char

      @term.showCursor()
      this.emit 'raw-terminal-char-copy-done'

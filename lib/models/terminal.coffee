Xterm = require './xterm-wrapper'
ipc = require 'ipc'
{EventEmitter} = require 'events'

module.exports =
class Terminal extends EventEmitter
  constructor: (ws_url, isTermView=false) ->
    rows = if isTermView then 26 else 18
    @term = new Xterm(cursorBlink: true)
    window.term = @term
    ipc.send 'register-new-terminal', ws_url
    @setListeners()

  updateConnectionState: (state) ->
    if state == 'closed'
      @emit 'terminal-session-closed'
    else
      @emit 'terminal-session-opened'

  setListeners: () ->
    ipc.on 'terminal-message', (message) =>
      @emit 'terminal-message-received', message

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
          @emit 'raw-terminal-char-copy-received', char

      # Sadly, this doesn't work yet...but it's a start
      #swapNode = existingNodes[0]
      #if swapNode && lastNode
        #swapNode.style.display = 'inline'
        #lastNode.style.display = 'inline'
        #lastNode.innerHTML = lastNode.innerHTML.replace(/(&nbsp;)+$/, '')
        #swapNode.parentNode.insertBefore(lastNode, swapNode)

      @term.showCursor()
      @emit 'raw-terminal-char-copy-done'

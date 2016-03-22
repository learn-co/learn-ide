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

      console.log(JSON.stringify(lastNode.innerText))
      for char in lastNode.innerText
        this.emit 'raw-terminal-char-copy-received', char

      @term.showCursor()
      #text = lastNode.innerText

      #@term.cursorBlink = false
      #existingNodes[0].innerText = lastNode.innerText
      #@term.cursorBlink = true
      #@term.startBlink()
      #@term.refreshBlink()
        #existingNodes[index].innerText = node.innerText

      window.term = @term
      #document.getElementsByClassName('terminal')[0].innerHTML = newHtml
      #@term.showCursor()
      #@term.initGlobal()
      #@term.refresh(0, @term.rows - 1)
      #@term.reset()
      #@term.refreshBlink()
      #@term.emit 'refresh-view'

  reset: (termView) ->
    @term.emit('data', "\r") # This doesn't work yet
    @ws.close()
    @ws = new WebSocket(@ws_url)
    @ws.onopen = =>
      termView.reset(@ws)

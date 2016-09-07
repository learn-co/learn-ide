Term = require './term-wrapper'
ipc  = require 'ipc'
utf8      = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
Websocket = require('websocket').w3cwebsocket

module.exports =
class Terminal extends EventEmitter
  constructor: (ws_url, isTermView=false) ->
    rows = if isTermView then 26 else 18
    @term = new Term(cols: 80, rows: rows, useStyle: no, screenKeys: no, scrollback: yes)
    window.term = @term

    @ws_url = ws_url
    @connect()
    @setListeners()

  connect: () ->
    @socket = new Websocket @ws_url

    @socket.onopen = () ->
      console.log('opened socket for terminal')

    @socket.onmessage = (msg) =>
      console.log('websocket encoded: ', {msg: msg.data})
      decoded = utf8.decode(window.atob(msg.data))
      console.log('websocket decoded: ', {decoded: decoded})
      @emit 'terminal-message-received', msg.data

    @socket.onclose = () ->
      console.log('connection closed')

    @socket.onerror = (e) ->
      console.log('error on terminal connection')
      console.error(e)

      
    @singleSocket = new SingleSocket @ws_url,
      onopen: () ->
        console.log('opened socket for single socket')
      onmessage: (msg) =>
        console.log('singlesocket encoded: ', {msg: msg})
        decoded = utf8.decode(window.atob(msg))
        console.log('singlesocket decoded: ', {decoded: decoded})
        # @emit 'terminal-message-received', msg
      onclose: () ->
        console.log('connection closed')
      onerror: (e) ->
        console.log('error on terminal connection')
        console.error(e)


  send: (data) ->
    console.log('sending:::', data)
    @socket.send(data)
    @singleSocket.send(data)

  # updateConnectionState: (state) ->
    # if state == 'closed'
      # this.emit 'terminal-session-closed'
    # else
      # this.emit 'terminal-session-opened'

  setListeners: () ->
    ipc.on 'request-terminal-view', (request) =>
      ipc.send 'terminal-view-response',
        index: request.index
        html: document.getElementsByClassName('terminal')[0].innerHTML

    # ipc.on 'connection-state', (state) =>
      # @updateConnectionState(state)

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

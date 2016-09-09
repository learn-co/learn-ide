Term = require './term-wrapper'
ipc  = require 'ipc'
utf8      = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'

module.exports =
class Terminal extends EventEmitter
  constructor: (ws_url, isTermView=false) ->
    rows = if isTermView then 26 else 18
    @term = new Term(cols: 80, rows: rows, useStyle: no, screenKeys: no, scrollback: yes)
    window.term = @term
    @ws_url = ws_url
    @connect()

  connect: () ->
    @socket = new SingleSocket @ws_url,
      onopen: () =>
        @emit 'open'
      onmessage: (msg) =>
        @emit 'message', utf8.decode(window.atob(msg))
      onclose: () =>
        @emit 'close'
      onerror: (e) ->
        @emit 'error', e

  send: (data) ->
    @socket.send(data)

ipc  = require 'ipc'
utf8      = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'

module.exports =
class Terminal extends EventEmitter
  constructor: (url) ->
    @url = url
    @connect()

  connect: () ->
    @socket = new SingleSocket @url,
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

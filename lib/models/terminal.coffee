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
        console.log('open')
        @emit 'open'
      onmessage: (msg) =>
        console.log('message', msg)
        @emit 'message', utf8.decode(window.atob(msg))
      onclose: () =>
        console.log('close')
        @emit 'close'
      onerror: (e) ->
        console.log('error', e)
        @emit 'error', e

  send: (data) ->
    @socket.send(data)

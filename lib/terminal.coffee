ipc  = require 'ipc'
utf8      = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
atomHelper = require './atom-helper'

module.exports =
class Terminal extends EventEmitter
  constructor: (url) ->
    @url = url
    @connect()

  connect: () ->
    @waitForSocket = new Promise (resolve, reject) =>
      @socket = new SingleSocket @url, {spawn: atomHelper.spawn}

      @socket.on 'open', =>
        console.log('open')
        @emit 'open'
        resolve()

      @socket.on 'message', (msg) =>
        console.log('message', msg)
        @emit 'message', utf8.decode(window.atob(msg))

      @socket.on 'close', () =>
        console.log('close')
        @emit 'close'

      @socket.on 'error', (e) =>
        console.log('error', e)
        @emit 'error', e
        reject(e)

  reset: () ->
    @socket.reset()

  send: (data) ->
    console.log('sending data over socket', data)
    @waitForSocket.then =>
      @socket.send(data)

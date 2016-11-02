utf8 = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
atomHelper = require './atom-helper'

module.exports = class Terminal extends EventEmitter
  constructor: (args) ->
    args || (args = {})

    @host = args.host
    @port = args.port
    @path = args.path
    @token = args.token

    @isConnected = false
    @hasFailed = false

    @connect()

  connect: (token) ->
    @waitForSocket = new Promise (resolve, reject) =>
      @socket = new SingleSocket @url(),
        spawn: atomHelper.spawn
        silent: true

      @socket.on 'open', =>
        @isConnected = true
        @hasFailed = false
        @emit 'open'
        resolve()

      @socket.on 'message', (msg) =>
        @emit 'message', utf8.decode(window.atob(msg))

      @socket.on 'close', () =>
        @isConnected = false
        @hasFailed = true
        @emit 'close'

      @socket.on 'error', (e) =>
        @isConnected = false
        @hasFailed = true
        @emit 'error', e
        reject(e)

  url: ->
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}"

  reset: ->
    @socket.close()
    setTimeout(@connect.bind(this), 100)

  send: (data) ->
    if @isConnected
      @socket.send(data)
    else
      if @hasFailed
        @reset()
        setTimeout =>
          @waitForSocket.then =>
            @socket.send(data)
        , 200
      else
        @waitForSocket.then =>
          @socket.send(data)

  updateToken: (token) ->
    @token = token

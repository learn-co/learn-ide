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
    @connect()

  connect: (token) ->
    @waitForSocket = new Promise (resolve, reject) =>
      @socket = new SingleSocket @url(),
        spawn: atomHelper.spawn
        silent: true

      @socket.on 'open', =>
        @isConnected = true
        @emit 'open'
        resolve()

      @socket.on 'message', (msg) =>
        @emit 'message', utf8.decode(window.atob(msg))

      @socket.on 'close', () =>
        @isConnected = false
        @emit 'close'

      @socket.on 'error', (e) =>
        @isConnected = false
        @emit 'error', e
        reject(e)

  url: ->
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}"

  reset: ->
    @socket.close()
    setTimeout(@connect.bind(this), 100)

  send: (data) ->
    if @socket
      @socket.send(data)

  updateToken: (token) ->
    @token = token

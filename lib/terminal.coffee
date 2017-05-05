{EventEmitter} = require 'events'
atomHelper = require './atom-helper'
path = require 'path'
bus = require './event-bus'
AtomSocket = require('atom-socket')

module.exports = class Terminal extends EventEmitter
  constructor: (args) ->
    args || (args = {})

    @host = args.host
    @port = args.port
    @path = args.path
    @token = args.token

    @hasFailed = false

    @connect()

  connect: (token) ->
    @socket = new AtomSocket('term', @url())

    @waitForSocket = new Promise (resolve, reject) =>
      @socket.on 'open', (e) =>
        @emit 'open', e
        resolve()

      @socket.on 'open:cached', (e) =>
        @emit 'open', e
        resolve()

      @socket.on 'message', (message) =>
        decoded = new Buffer(message or '', 'base64').toString()
        @emit('message', decoded)

      @socket.on 'close', (e) =>
        @emit 'close', e

      @socket.on 'error', (e) =>
        @emit 'error', e

  url: ->
    {version} = require '../package.json'
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}&version=#{version}"

  reset: ->
    @socket.reset()

  send: (msg) ->
    if @waitForSocket
      @waitForSocket.then =>
        @waitForSocket = null
        @socket.send(msg)
    else
      @socket.send(msg)

  toggleDebugger: () ->
    @socket.toggleDebugger()

  debugInfo: ->
    {
      host: @host,
      port: @port,
      path: @path,
      token: @token,
      socket: @socket
    }

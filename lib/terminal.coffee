utf8 = require 'utf8'
{EventEmitter} = require 'events'
atomHelper = require './atom-helper'
path = require 'path'
bus = require('./event-bus')()
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

        if @captureResponse? and decoded.includes(@captureResponse.msg)
          return

        if @captureResponse? and @captureResponse.test(decoded)
          @captureResponse.resolve(decoded)
          @captureResponse = null
          return

        @emit('message', decoded)

      @socket.on 'close', (e) =>
        @emit 'close', e

      @socket.on 'error', (e) =>
        @emit 'error', e

  url: ->
    version = require './version'
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}&version=#{version}"

  reset: ->
    @socket.reset()

  sendAndCaptureResponse: (msg, test) ->
    new Promise (resolve) =>
      @captureResponse = {msg, test, resolve}
      @send(msg)

  send: (msg) ->
    if @waitForSocket
      @waitForSocket.then =>
        @waitForSocket = null
        @socket.send(msg)
    else
      @socket.send(msg)

  toggleDebugger: () ->
    @socket.toggleDebugger()

  getHostIp: () ->
    key = 'host_ip:'

    @sendAndCaptureResponse("echo #{key}$HOST_IP && clear\r", (msg) =>
      msg.startsWith(key)
    ).then((msg) =>
      msg.replace(key, '').replace(/\s/g, '')
    )

  debugInfo: ->
    {
      host: @host,
      port: @port,
      path: @path,
      token: @token,
      socket: @socket
    }

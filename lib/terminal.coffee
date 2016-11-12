utf8 = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
atomHelper = require './atom-helper'
logger = require './logger'
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

    @isConnected = false
    @hasFailed = false

    @connect()

  connect: (token) ->
    @socket = new AtomSocket('term', @url())

    @waitForSocket = new Promise (resolve, reject) =>
      @socket.on 'open', =>
        @emit 'open'
        resolve()

      @socket.on 'message', (message) =>
        @emit 'message', utf8.decode(atob(message))

      @socket.on 'close', =>
        @emit 'close'

      @socket.on 'error', (e) =>
        @emit 'error', e

  url: ->
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}"

  reset: ->
    logger.info('term:reset')
    @socket.reset()

  send: (msg) ->
    @socket.send(msg)

  debugInfo: ->
    {
      host: @host,
      port: @port,
      path: @path,
      token: @token,
      isConnected: @isConnected,
      hasFailed: @hasFailed,
      socket: @socket
    }

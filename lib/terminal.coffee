utf8 = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
atomHelper = require './atom-helper'
logger = require './logger'
path = require 'path'
bus = require('./event-bus')()

SocketDrawer = require('socket-drawer')

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
    @socket = new SocketDrawer('term', @url())

    @waitForSocket = new Promise (resolve, reject) =>
      @socket.on 'open', =>
        @emit 'open'
        resolve()

      @socket.on 'message', (message) =>
        console.log('message coming out of socket', message)
        @emit 'message', utf8.decode(atob(message))
        console.log('message over localStorage', message)

  url: ->
    protocol = if @port == 443 then 'wss' else 'ws'
    "#{protocol}://#{@host}:#{@port}/#{@path}?token=#{@token}"

  reset: ->
    logger.info('term:reset')
    @socket.close().then =>
      @connect()
    .catch (err) =>
      @emit 'error', err

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

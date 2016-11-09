utf8 = require 'utf8'
{EventEmitter} = require 'events'
SingleSocket = require 'single-socket'
atomHelper = require './atom-helper'
logger = require './logger'
path = require 'path'

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
        logFile: path.join(atom.getConfigDirPath(), 'learn-ide.log')

      @socket.on 'open', =>
        logger.info('term:open')
        @isConnected = true
        @hasFailed = false
        @emit 'open'
        resolve()

      @socket.on 'message', (msg) =>
        logger.info('term:msg', {msg: msg})
        @emit 'message', utf8.decode(window.atob(msg))

      @socket.on 'close', () =>
        @isConnected = false
        @hasFailed = true
        @emit 'close'
        logger.info('term:close')

      @socket.on 'error', (e) =>
        @isConnected = false
        @hasFailed = true
        @emit 'error', e
        logger.error('term:error', {debug: @debugInfo(), error: e})
        reject(e)

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
    logger.info('term:send', {msg: msg})
    if @isConnected
      @socket.send(msg)
    else
      if @hasFailed
        @reset()
        setTimeout =>
          @waitForSocket.then =>
            @socket.send(msg)
        , 200
      else
        @waitForSocket.then =>
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

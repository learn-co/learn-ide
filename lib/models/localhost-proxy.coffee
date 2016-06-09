net = require 'net'
httpProxy = require 'http-proxy'

module.exports = class LocalhostProxy
  constructor: (port) ->
    @port = port
    @bound = false
    @remoteHost = 'http://159.203.117.55'

  start: ->
    @withAvailablePort((available) =>
      if !!available
        @bound = true
        httpProxy.createProxyServer({target: @remoteHost + ':' + @port}).listen(3000, 'localhost')
    )

  withAvailablePort: (callback) ->
    try
      server = net.createServer()
      server.listen 3000, 'localhost'

      server.on 'error', (e) ->
        callback false
      server.on 'listening', (e) ->
        server.close()
        callback true
    catch error
      callback false

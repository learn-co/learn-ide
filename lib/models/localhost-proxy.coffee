net = require 'net'
httpProxy = require 'http-proxy'

module.exports = class LocalhostProxy
  constructor: (port) ->
    @port = port
    @remoteHost = 'http://159.203.117.55'
    @desiredPorts = ['3000', '4000', '8000', '9393']

  start: ->
    @withAvailablePort((ports) =>
      console.log ports
      server = httpProxy.createProxyServer({target: @remoteHost + ':' + @port})

      for port in @desiredPorts
        console.log 'Port: ' + port + ' Available: ' + !!ports[port]
        if !!ports[port]
          server.listen(parseInt(port), 'localhost')
    )

  withAvailablePort: (callback) ->
    ports = {}

    for port in @desiredPorts
      try
        server = net.createServer()
        server.listen parseInt(port), 'localhost'

        server.on 'error', (e) ->
          ports[port] = false
        server.on 'listening', (e) ->
          server.close()
          ports[port] = true
      catch error
        ports[port] = false

    callback(ports)

net = require 'net'
httpProxy = require 'http-proxy'

module.exports = class LocalhostProxy
  constructor: (port) ->
    @port = port
    @remoteHost = 'http://ile.learn.co'
    @desiredPorts = ['3000', '4000', '4567', '8000', '9292', '9393']

  start: ->
    @withAvailablePort((ports) =>
      server = httpProxy.createProxyServer({target: @remoteHost + ':' + @port})

      for port in @desiredPorts
        console.log 'Port: ' + port + ' Available: ' + !!ports[port]
        if !!ports[port]
          server.listen(parseInt(port), 'localhost')
          console.log 'Listening on port: ' + port
        else
          console.log 'NOT listening on port: ' + port
    )

  withAvailablePort: (callback) ->
    ports = {}

    @desiredPorts.forEach (port) ->
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

    allChecked = =>
      @desiredPorts.every((port) ->
        ports[port] != null
      )

    checkInterval = setInterval(=>
      console.log 'Finished checking available ports: ' + allChecked(ports)
      if allChecked()
        clearInterval(checkInterval)
        callback(ports)
    , 100)

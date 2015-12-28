require 'thin'
require 'faye/websocket'
require 'pty'

stdout, stdin, pid = PTY.spawn("/bin/bash -il")

WebsocketServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :open do
    Thread.new do
      loop do
        @ws.send(stdout.readpartial(4096))
      end
    end
  end

  @ws.on :message do |event|
    stdin << event.data
  end

  @ws.on :close do |event|
    @ws = nil
  end

  @ws.rack_response
end

Faye::WebSocket.load_adapter('thin')

run WebsocketServer

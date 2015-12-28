require 'pty'
require 'rack'
require 'thin'
require 'faye/websocket'

Faye::WebSocket.load_adapter('thin')

TerminalServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :open do
    @stdout, @stdin, @pid = PTY.spawn("/bin/bash -il")

    Thread.new do
      loop do
        @ws.send(@stdout.readpartial(4096))
      end
    end
  end

  @ws.on :message do |event|
    @stdin << event.data
  end

  @ws.on :close do |event|
    @ws = nil
  end

  @ws.rack_response
end

run TerminalServer

require 'faye/websocket'
require 'pty'
require 'pry'

PTY.spawn("/bin/bash -li") do |stdout, stdin, pid|
  WebsocketServer = lambda do |env|
    @ws = Faye::WebSocket.new(env)

    def read_without_blocking(file)
      begin
        @ws.send(file.read_nonblock(1024 * 1024))
      rescue IO::WaitReadable
      end
    end

    @ws.on :open do |event|
      read_without_blocking(stdout)
    end

    @ws.on :message do |event|
      stdin.write(event.data)
      # hack for making sure tty buffer is filled
      sleep 0.01
      read_without_blocking(stdout)
    end

    @ws.on :close do |event|
      @ws = nil
    end

    @ws.rack_response
  end
end

Faye::WebSocket.load_adapter('thin')

run WebsocketServer

require 'thin'
require 'faye/websocket'
require './synced_fs/event.rb'

Faye::WebSocket.load_adapter('thin')

SyncedFSServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :message do |event|
    puts SyncedFS::Event.resolve(event.data).inspect
    @ws.send 'ok'
  end

  Thread.new do
    loop do
      sleep 5
      @ws.ping
    end
  end

  @ws.rack_response
end

run SyncedFSServer

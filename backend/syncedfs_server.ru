require 'thin'
require 'faye/websocket'
require_relative 'synced_fs/event.rb'
require_relative 'synced_fs/events/local_open'
require_relative 'synced_fs/events/local_save'

Faye::WebSocket.load_adapter('thin')

SyncedFSServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :message do |event|
    event = SyncedFS::Event.resolve(event.data)
    event.process
    puts event.inspect
    @ws.send(event.reply)
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

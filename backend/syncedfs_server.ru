require 'rack'
require 'thin'
require 'faye/websocket'
require './synced_fs/event.rb'
require 'pry'

Faye::WebSocket.load_adapter('thin')

SyncedFSServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :message do |event|
    puts SyncedFS::Event.resolve(event.data).inspect
  end

  @ws.rack_response
end

run SyncedFSServer

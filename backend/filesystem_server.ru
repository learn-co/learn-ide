require 'rack'
require 'thin'
require 'faye/websocket'
require 'etc'
require 'pry'

class FileChange
  def initialize(change)
    parts     = change.split(":")
    @path     = parts[0]
    @hash     = parts[1]
    @contents = parts[2..-1].join('')
  end
end

Faye::WebSocket.load_adapter('thin')

FilesystemServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :message do |event|
    puts FileChange.new(event.data).inspect
  end

  @ws.rack_response
end

run FilesystemServer

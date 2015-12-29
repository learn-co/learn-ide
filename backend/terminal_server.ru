require 'thin'
require 'faye/websocket'
require './terminal/session.rb'

Faye::WebSocket.load_adapter('thin')

TerminalServer = lambda do |env|
  @ws = Faye::WebSocket.new(env)

  @ws.on :open do
    @term = Terminal::Session.new
    @term.bind_to(@ws)
  end

  @ws.on :message do |event|
    @term.write(event.data)
  end

  @ws.on :close do |event|
    @ws = nil
  end

  @ws.rack_response
end

run TerminalServer

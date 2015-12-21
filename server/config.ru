require 'faye/websocket'

WebsocketServer = lambda do |env|
  ws = Faye::WebSocket.new(env)

  ws.on :open do |event|
    p [:open]
    ws.send("Learn says 'Hello'")
  end

  ws.on :message do |event|
    p [:message, event.data]
    ws.send(event.data)
  end

  ws.on :close do |event|
    p [:close, event.code, event.reason]
    ws = nil
  end

  ws.rack_response
end

Faye::WebSocket.load_adapter('thin')

run WebsocketServer

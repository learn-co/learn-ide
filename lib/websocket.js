require('coffee-script/register')

var path = require('path')
var pagebus = require('page-bus')

var busPath = path.join(__dirname, 'event-bus')
var bus = require(busPath)()

var config = require('./config')
var token = require('./token')



var protocol = config.port === 443 ? 'wss' : 'ws'
var url = `${protocol}://${config.host}:${config.port}/${config.path}?token=${token.get()}`
var ws = new WebSocket(url)

ws.onopen = () => {
  bus.emit('open')
  console.log('opened socket')
}

ws.onmessage = (msg) => {
  bus.emit('message', msg.data)
  console.log(msg.data)
}

bus.on('send', (message) => {
  ws.send(message)
})

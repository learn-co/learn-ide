require('coffee-script/register')
var path = require('path')
console.log(localStorage.getItem('updateCheck'))
var pagebus = require('page-bus')

console.log('hello??')
var busPath = path.join(__dirname, 'event-bus')
console.log(busPath)
var bus = require(busPath)()

console.log('ehllo')
var config = require('./config')
var token = require('./token')



var protocol = config.port === 443 ? 'wss' : 'ws'
console.log(protocol)
var url = `${protocol}://${config.host}:${config.port}/${config.path}?token=${token.get()}`
console.log(url)
var ws = new WebSocket(url)

ws.onopen = () => {
  bus.emit('open')
  console.log('opened socket')
}

ws.onmessage = (msg) => {
  bus.emit('message', msg.data)
  console.log(msg)
  console.log(msg.data)
}

path = require 'path'
_ = require 'underscore-plus'

require('dotenv').config({
  path: path.join(__dirname, '../.env'),
  silent: true
})

config = _.defaults
  host: process.env['IDE_WS_HOST'],
  port: process.env['IDE_WS_PORT']
,
  host: 'ile.learn.co',
  port: 443,
  protocol: 'wss'

if config.port != 443
  config.protocol = 'ws'

config.terminalServerURL = ->
  "#{config.protocol}://#{config.host}:#{config.port}"

module.exports = config

path = require 'path'
_ = require 'underscore-plus'

require('dotenv').config({
  path: path.join(__dirname, '../.env'),
  silent: true
})

module.exports = _.defaults
  host: process.env['IDE_WS_HOST'],
  port: process.env['IDE_WS_PORT']
,
  host: 'ile.learn.co',
  port: 443

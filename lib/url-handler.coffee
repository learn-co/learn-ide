ipc = require 'ipc'
url = require 'url'

module.exports = ({args}) ->
  ipc.send('open', {learnOpen: true})

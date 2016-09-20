url = require 'url'
ipc = require 'ipc'
localStorage = require './local-storage'

getLabSlug = ->
  {urlToOpen} = JSON.parse(decodeURIComponent(location.hash.substr(1)))
  url.parse(urlToOpen).pathname.substring(1)

module.exports = ({blobStore}) ->
  localStorage.set('learnOpenLabSlug', getLabSlug())
  ipc.send('command', 'application:new-window')
  Promise.resolve()

url = require 'url'
{ipcRenderer} = require 'electron'
localStorage = require './local-storage'
bus = require('./event-bus')()

getLabSlug = ->
  {urlToOpen} = JSON.parse(decodeURIComponent(location.hash.substr(1)))
  url.parse(urlToOpen).pathname.substring(1)

module.exports = ({blobStore}) ->
  if localStorage.get('lastFocusedWindow')
    window.bus  = bus
    bus.emit('learn:open', {timestamp: Date.now(), slug: getLabSlug()})
  else
    localStorage.set('learnOpenLabOnActivation', getLabSlug())
    ipcRenderer.send('command', 'application:new-window')
  
  Promise.resolve()

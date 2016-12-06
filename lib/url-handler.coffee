url = require 'url'
{ipcRenderer} = require 'electron'
localStorage = require './local-storage'
bus = require('./event-bus')()

getLabSlug = ->
  {urlToOpen} = JSON.parse(decodeURIComponent(location.hash.substr(1)))
  url.parse(urlToOpen).pathname.substring(1)

openInNewWindow = ->
  localStorage.set('learnOpenLabOnActivation', getLabSlug())
  ipcRenderer.send('command', 'application:new-window')

openInExistingWindow = ->
  bus.emit('learn:open', {timestamp: Date.now(), slug: getLabSlug()})

windowOpen = ->
  localStorage.get('lastFocusedWindow')

onWindows = ->
  process.platform == 'win32'

module.exports = ({blobStore}) ->
  if !windowOpen() || onWindows()
    openInNewWindow()
  else
    openInExistingWindow()
  
  Promise.resolve()

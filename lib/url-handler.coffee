localStorage = require './local-storage'
ipc = require 'ipc'
url = require 'url'
path = require 'path'
app = require 'electron'
# atom = require 'atom'

getLabToOpen = ->
  urlToOpen = JSON.parse(decodeURIComponent(location.hash.substr(1))).urlToOpen
  url.parse(urlToOpen).pathname.substring(1)

module.exports = ({blobStore}) ->
  window.app = app
  console.log('app')
  console.log(app)
  labToOpen = getLabToOpen()
  # console.log(labToOpen)
  # window.atom = atom
  # window.blobStore = blobStore
  localStorage.set('learnOpenURL', labToOpen)
  # throw new Error
  ipc.send('command', 'application:new-window')

  # throw new Error(urlToOpen)
  new Promise (resolve, reject) -> resolve()

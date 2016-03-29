ipc = require 'ipc'
url = require 'url'

module.exports = ({blobStore}) ->
  #{urlToOpen} = JSON.parse(decodeURIComponent(location.search.substr(14)))

  #console.log urlToOpen
  ipc.send('call-window-method', 'show')
  ipc.send('call-window-method', 'focus')
  window.focus()
  #ipc.send('call-window-method', 'openDevTools')

  #parsed = url.parse urlToOpen, true
  #console.log parsed

  #filePath = "/Users/tclem/github/github/#{parsed.query.filepath}"
  #console.log filePath

  # TODO Once you have the path to open, uncomment this line
  ipc.send('open', {pathsToOpen: ['/Users/loganhasson/Desktop/ile_open.html']})
  #path = require 'path'
  #require './window'
  #{getWindowLoadSettings} = require './window-load-settings-helpers'

  #{resourcePath, isSpec, devMode} = getWindowLoadSettings()

  # Add application-specific exports to module search path.
  #exportsPath = path.join(resourcePath, 'exports')
  #require('module').globalPaths.push(exportsPath)
  #process.env.NODE_PATH = exportsPath

  # Make React faster
  #process.env.NODE_ENV ?= 'production' unless devMode

  #AtomEnvironment = require './atom-environment'
  #ApplicationDelegate = require './application-delegate'
  #window.atom = new AtomEnvironment({
    #window, document, blobStore,
    #applicationDelegate: new ApplicationDelegate,
    #configDirPath: process.env.ATOM_HOME
    #enablePersistence: true
  #})

  #atom.displayWindow()
  #atom.startEditorWindow()

  # Workaround for focus getting cleared upon window creation
  #windowFocused = ->
    #window.removeEventListener('focus', windowFocused)
    #setTimeout (-> document.querySelector('atom-workspace').focus()), 0
  #window.addEventListener('focus', windowFocused)


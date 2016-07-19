remote = require 'remote'
shell = require 'shell'
BrowserWindow = remote.require('browser-window')

module.exports =
class BrowserWindowWrapper
  constructor: (url, options = {}, @openNewWindowExternally = true) ->
    options.show ?= false
    options.width ?= 400
    options.height ?= 600
    options.skipTaskbar ?= true
    options.menuBarVisible ?= false

    @win = new BrowserWindow(options)
    @webContents = @win.webContents
    @forceBrowserWindowOptions(@win, options)

    @handleEvents()
    @win.loadUrl(url) # TODO: handle failed load

  handleEvents: =>
    @webContents.on 'did-finish-load', =>
      @win.show()

    if @openNewWindowExternally
      @webContents.on 'new-window', (e, url) =>
        e.preventDefault()
        @win.destroy()
        shell.openExternal(url)

  forceBrowserWindowOptions: (win, options) ->
    # these options fail as arguments to the BrowserWindor constructor
    {skipTaskbar, menuBarVisible, title} = options

    win.setTitle(title) if title?
    win.setSkipTaskbar(skipTaskbar)
    win.setMenuBarVisibility(menuBarVisible)

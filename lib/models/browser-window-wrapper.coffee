remote = require 'remote'
shell = require 'shell'
BrowserWindow = remote.require('browser-window')

module.exports =
class BrowserWindowWrapper
  constructor: (url, options = {}, @openNewWindowExternally = true) ->
    options.show ?= false
    options.width ?= 400
    options.height ?= 600

    @win = new BrowserWindow(options)
    @webContents = @win.webContents

    @handleEvents()
    @win.loadUrl(url)

  handleEvents: =>
    @webContents.on 'did-finish-load', =>
      @win.show()

    if @openNewWindowExternally
      @webContents.on 'new-window', (e, url) =>
        e.preventDefault()
        @win.destroy()
        shell.openExternal(url)

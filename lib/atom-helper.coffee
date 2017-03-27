localStorage = require './local-storage'

packageName = ->
  pkg = require '../package.json'
  pkg.name

module.exports =
  isLastFocusedWindow: ->
    parseInt(localStorage.get('lastFocusedWindow')) == process.pid

  setLastFocusedWindow: ->
    localStorage.set('lastFocusedWindow', process.pid)

  trackFocusedWindow: ->
    @setLastFocusedWindow()
    window.onfocus = @setLastFocusedWindow

  cleanup: ->
    if @isLastFocusedWindow()
      localStorage.delete('lastFocusedWindow')

  emit: (key, detail) ->
    atom.emitter.emit(key, detail)

  on: (key, callback) ->
    atom.emitter.on(key, callback)

  closePaneItems: ->
    atom.workspace.getPanes().forEach (pane) ->
      pane.close()

  resetPackage: ->
    atom.packages.deactivatePackage(packageName())
    atom.packages.activatePackage(packageName()).then ->
      atom.menu.sortPackagesMenu()

  reloadStylesheets: ->
    pkg = atom.packages.getActivePackage(packageName())
    pkg.reloadStylesheets()

  addStylesheet: (css) ->
    atom.styles.addStyleSheet(css)


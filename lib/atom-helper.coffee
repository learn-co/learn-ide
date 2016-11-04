localStorage = require './local-storage'

module.exports =
  isLastFocusedWindow: ->
    parseInt(localStorage.get('lastFocusedWindow')) == process.pid

  setLastFocusedWindow: ->
    localStorage.set('lastFocusedWindow', process.pid)

  trackFocusedWindow: ->
    @setLastFocusedWindow()
    window.onfocus = @setLastFocusedWindow

  spawn: (modulePath) ->
    {BufferedNodeProcess} = require 'atom'
    new BufferedNodeProcess({command: modulePath})

  cleanup: ->
    if @isLastFocusedWindow()
      localStorage.delete('lastFocusedWindow')

  on: (event, callback) ->
    atom.emitter.on(event, callback)

  closePaneItems: ->
    atom.workspace.getPanes().forEach (pane) ->
      pane.close()


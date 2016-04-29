{$, View}  = require 'atom-space-pen-views'
ipc = require 'ipc'

module.exports =
class SyncedFSView extends View
  @content: ->
    @div class: 'learn-synced-fs-status', =>
      @div class: 'learn-status-icon inline-block icon-terminal', id: 'learn-status-icon', ' Learn'
      @div class: 'active learn-popout-terminal-icon inline-block icon-share-icon', id: 'learn-popout-terminal-icon', 'Popout'

  constructor: (state, fs, emitter) ->
    super

    @fs = fs

    @element.style.color = '#d92626'
    @emitter = emitter

    @handleEvents()

    ipc.send 'connection-state-request'

  handleEvents: () ->
    ipc.on 'connection-state', (state) =>
      this.updateConnectionState(state)

    this.on 'click', =>
      workspaceView = atom.views.getView(atom.workspace)
      atom.commands.dispatch(workspaceView, 'application:new-popout-terminal')
      #@emitter.emit 'toggleTerminal'

  statusIcon: =>
    @element.getElementsByClassName('learn-status-icon')[0]

  popoutIcon: =>
    @element.getElementsByClassName('learn-popout-terminal-icon')[0]

  updateConnectionState: (state) =>
    if state == 'open'
      @statusIcon().style.color = '#73c990'
      @statusIcon().textContent = ' Learn'
    else
      @statusIcon().style.color = '#d92626'
      @statusIcon().textContent = ' Learn [DISCONNECTED]'

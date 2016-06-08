{$, View}  = require 'atom-space-pen-views'
ipc = require 'ipc'

module.exports =
class SyncedFSView extends View
  @content: ->
    @div class: 'learn-synced-fs-status', =>
      @div class: 'learn-status-icon inline-block icon-terminal', id: 'learn-status-icon', ' Learn'
      @div class: 'learn-popout-terminal-icon inline-block icon-link-external', id: 'learn-popout-terminal-icon'

  constructor: (state, fs, emitter, isTerminalWindow) ->
    super

    @fs = fs

    @emitter = emitter

    @handleEvents()

    if isTerminalWindow
      @termPoppedOut = 1
      @popoutIcon().classList.add('inactive')
    else
      @popoutIcon().classList.add('active')
      @termPoppedOut = 0

    ipc.send 'connection-state-request'

  handleEvents: () ->
    ipc.on 'connection-state', (state) =>
      this.updateConnectionState(state)

    ipc.on 'terminal-popped-in', (state) =>
      console.log 'popped in!'
      if @termPoppedOut == 1
        @emitter.emit 'toggleTerminal', true
        @termPoppedOut = 0
        @togglePopoutIcon()

    @popoutIcon().addEventListener 'click', =>
      if @termPoppedOut == 0
        workspaceView = atom.views.getView(atom.workspace)
        atom.commands.dispatch(workspaceView, 'application:new-popout-terminal')
        @termPoppedOut = 1
        @togglePopoutIcon()
        setTimeout =>
          @emitter.emit 'toggleTerminal'
        , 100

    @statusIcon().addEventListener 'click', (e) ->
      if e.target.dataset.status is 'bad'
        workspaceView = atom.views.getView(atom.workspace)
        atom.commands.dispatch(workspaceView, 'integrated-learn-environment:reset')

  togglePopoutIcon: =>
    if @popoutIcon().classList.contains('inactive')
      @popoutIcon().classList.remove('inactive')
      @popoutIcon().classList.add('active')
    else
      @popoutIcon().classList.remove('active')
      @popoutIcon().classList.add('inactive')

  statusIcon: =>
    @element.getElementsByClassName('learn-status-icon')[0]

  popoutIcon: =>
    @element.getElementsByClassName('learn-popout-terminal-icon')[0]

  updateConnectionState: (state) =>
    if state is 'open'
      @statusIcon().textContent = ' Learn'
      @statusIcon().dataset.status = 'good'
    else
      @statusIcon().textContent = ' Learn... reconnect?'
      @statusIcon().dataset.status = 'bad'

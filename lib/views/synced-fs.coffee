{$, View}  = require 'atom-space-pen-views'
ipc = require 'ipc'
localStorage = require('../local-storage')
bus = require('../event-bus')()

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

    bus.on 'learn:terminal:popin', () =>
      if @termPoppedOut is 1
        @emitter.emit 'toggleTerminal', true
        @termPoppedOut = 0
        @togglePopoutIcon()

    @popoutIcon().addEventListener 'click', =>
      @popoutTerminal()

    @statusIcon().addEventListener 'click', (e) ->
      if e.target.dataset.status is 'bad'
        workspaceView = atom.views.getView(atom.workspace)
        atom.commands.dispatch(workspaceView, 'learn-ide:reset')

  popoutTerminal: ->
    if @termPoppedOut is 0
      localStorage.set('popoutTerminal', true)
      ipc.send('command', 'application:new-window')

      @termPoppedOut = 1
      @togglePopoutIcon()
      # setTimeout =>
      @emitter.emit 'toggleTerminal'
      # , 100

  togglePopoutIcon: =>
    @popoutIcon().classList.toggle('inactive')
    @popoutIcon().classList.toggle('active')

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

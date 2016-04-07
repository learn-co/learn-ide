{$, View}  = require 'atom-space-pen-views'
ipc = require 'ipc'

module.exports =
class SyncedFSView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block icon-terminal'

  constructor: (state, fs, emitter) ->
    super

    @fs = fs
    @text " Learn"
    @element.style.color = '#d92626'
    @emitter = emitter

    @handleEvents()

    ipc.send 'connection-state-request'

  handleEvents: () ->
    ipc.on 'connection-state', (state) =>
      this.updateConnectionState(state)

    this.on 'click', =>
      @emitter.emit 'toggleTerminal'

  updateConnectionState: (state) ->
    if state == 'open'
      @element.style.color = '#73c990'
      @element.textContent = ' Learn'
    else
      @element.style.color = '#d92626'
      @element.textContent = ' Learn [DISCONNECTED]'

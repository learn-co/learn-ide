{$, View}  = require 'atom-space-pen-views'
ipc = require 'ipc'

module.exports =
class SyncedFSView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block icon-terminal'

  constructor: (state, fs) ->
    super

    @fs = fs
    @text " Learn"
    @element.style.color = '#d92626'

    @handleEvents()

    ipc.send 'connection-state-request'

  handleEvents: () ->
    ipc.on 'connection-state', (state) =>
      this.updateConnectionState(state)

  updateConnectionState: (state) ->
    if state == 'open'
      @element.style.color = '#73c990'
    else
      @element.style.color = '#d92626'

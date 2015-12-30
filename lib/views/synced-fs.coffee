{$, View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block icon-terminal'

  constructor: (state, fs) ->
    super

    @fs = fs
    @ws = fs.ws

    # Default text
    @text(" Learn")
    @element.style.color = '#d92626'

    @handleEvents()

  handleEvents: ->
    @ws.onopen = (e) =>
      @element.style.color = '#73c990'
    @ws.onmessage = (e) =>
      console.log("SyncedFS debug: " + e)
    @ws.onclose = =>
      @element.style.color = '#d92626'

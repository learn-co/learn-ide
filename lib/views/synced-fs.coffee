{$, View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'learn-synced-fs-status inline-block'

  constructor: (state, fs) ->
    super

    @fs = fs
    @ws = fs.ws

    @text("Connecting to Learn...")

    @handleEvents()

  handleEvents: ->
    @ws.onopen = (e) =>
      @text("Connected to Learn")
    @ws.onclose = =>
      @text("Disconnected from Learn")

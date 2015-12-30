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
    @element.style.color = 'red'

    @handleEvents()

  handleEvents: ->
    @ws.onopen = (e) =>
      @element.style.color = 'green'
    @ws.onclose = =>
      @element.style.color = 'red'

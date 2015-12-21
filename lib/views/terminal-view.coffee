{$, View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel ile-terminal'
  initialize: (terminal) ->
    terminal.open(this.get(0))

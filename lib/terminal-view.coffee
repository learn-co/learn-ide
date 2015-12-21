{$, View} = require 'atom-space-pen-views'
term = require 'term.js'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel ile-terminal'

  initialize: ->
    terminal = new term.Terminal(useStyle: no, screenKeys: no)
    terminal.open(this.get(0))
    terminal.write("Hello World")

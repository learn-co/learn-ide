term = require 'term.js'

module.exports =
class TerminalFactory
  @create: ->
    new term.Terminal(cols: 80, rows: 24, useStyle: no, screenKeys: no, scrollback: yes)

{View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel ile-terminal'

  initialize: (state, terminal) ->
    @terminal = terminal
    @panel = atom.workspace.addBottomPanel(item: this, visible: false, className: 'ile-terminal-view')

    @terminal.open(this.get(0))

    @applyEditorStyling()
    @resize()
    @handleEvents()

  applyEditorStyling: ->
    @terminal.element.style.fontFamily = ->
      atom.config.get('editor.fontFamily') or "monospace"
    @terminal.element.style.fontSize = ->
      atom.config.get('editor.fontSize')

  handleEvents: ->
    @on 'focus', =>
      @resize()

  resize: ->
    element = @terminal.element
    sampleRow = element.lastChild
    rows = Math.floor(element.offsetWidth / sampleRow.offsetWidth)
    cols = Math.floor(element.offsetHeight / sampleRow.offsetHeight)

    # FIXME: sampleRow is returning 0 width, 0 height
    #@terminal.resize(cols, rows)

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()

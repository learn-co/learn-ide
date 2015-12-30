{$, View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel ile-terminal', =>
      @div class: 'terminal-view-resize-handle', style: 'height: 5px'

  initialize: (state, terminal) ->
    @term = terminal.term
    @panel = atom.workspace.addBottomPanel(item: this, visible: false, className: 'learn-terminal-view')
    @term.open(this.get(0))

    @applyEditorStyling()
    @handleEvents()

  applyEditorStyling: ->
    @term.element.style.height = '100%'
    @term.element.style.fontFamily = ->
      atom.config.get('editor.fontFamily') or "monospace"
    @term.element.style.fontSize = ->
      atom.config.get('editor.fontSize')

  handleEvents: ->
    @on 'focus', =>
      @resizeTerminal()
    @on 'mousedown', '.terminal-view-resize-handle', (e) =>
      @resizeStarted(e)

  resizeStarted: ->
    $(document).on('mousemove', @resize)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resize)
    $(document).off('mouseup', @resizeStopped)
    @resizeTerminal()

  resize: ({pageY, which}) =>
    return @resizeStopped() unless which is 1
    @height(window.innerHeight - pageY)

  resizeTerminal: ->
    {cols, rows} = @getDimensions()
    @term.resize(cols, rows)

  getDimensions: ->
    terminal = @find('.terminal')
    fakeRow = $("<div><span>&nbsp;</span></div>").css(visibility: 'hidden')
    terminal.append(fakeRow)
    fakeCol = fakeRow.children().first()
    cols = Math.floor(terminal.width() / fakeCol.width())
    rows = Math.floor(terminal.height() / fakeRow.height())
    fakeCol.remove()

    {cols, rows}

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()

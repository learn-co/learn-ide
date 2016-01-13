{$, View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel learn-terminal', =>
      @div class: 'terminal-view-resize-handle'

  initialize: (state, terminal) ->
    @term = terminal.term
    @ws = terminal.ws
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

    @term.on 'data', (data) =>
      @ws.send(data)

    @ws.onmessage = (e) =>
      @term.write(window.atob(e.data))
    @ws.onclose = =>
      @term.element.style.color = '#666'
      @term.cursorHidden = true

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
    fakeCol = fakeRow.children().first()

    terminal.append(fakeRow)
    cols = Math.floor(terminal.width() / fakeCol.width())
    rows = Math.floor(terminal.height() / fakeRow.height())
    fakeCol.remove()

    {cols, rows}

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()

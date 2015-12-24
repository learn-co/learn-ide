{$, View} = require 'atom-space-pen-views'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel ile-terminal', =>
      @div class: 'terminal-view-resize-handle', style: 'height: 5px'

  initialize: (state, terminal) ->
    @terminal = terminal
    @panel = atom.workspace.addBottomPanel(item: this, visible: false, className: 'ile-terminal-view')
    @terminal.open(this.get(0))
    @terminal.on 'open', ->
      @resizeTerminal()
    @applyEditorStyling()
    @handleEvents()

  applyEditorStyling: ->
    @terminal.element.style.height = '100%'
    @terminal.element.style.fontFamily = ->
      atom.config.get('editor.fontFamily') or "monospace"
    @terminal.element.style.fontSize = ->
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
    # inject fake row so we can get correct dimensions of 1x1
    fakeRow = $("<div><span>&nbsp;</span></div>").css(visibility: 'hidden')
    fakeCol = fakeRow.children().first()
    @find('.terminal').append(fakeRow)

    cols = Math.floor(@width() / fakeCol.width())
    rows = Math.floor(@height() / fakeRow.height())

    fakeRow.remove()
    @terminal.resize(cols, rows)

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()

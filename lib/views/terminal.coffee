{$, View} = require 'atom-space-pen-views'
utf8      = require 'utf8'
ipc       = require 'ipc'
Clipboard = require 'clipboard'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel learn-terminal', =>
      @div class: 'terminal-view-resize-handle'

  initialize: (state, terminal, openPath) ->
    @term = terminal.term
    @terminal = terminal
    @panel = atom.workspace.addBottomPanel(item: this, visible: false, className: 'learn-terminal-view')
    @openPath = openPath

    @term.open(this.get(0))
    @term.write('Connecting...\r')

    if !!process.platform.match(/win/)
      @term.on 'keydown', (e) =>
        if e.which == 67 && e.shiftKey && e.ctrlKey
          Clipboard.writeText(getSelection().toString())
        else if e.which == 86 && e.shiftKey && e.ctrlKey
          @term.emit 'data', Clipboard.readText()
    else
      this.on 'keydown', (e) =>
        if e.which == 67 && e.metaKey
          Clipboard.writeText(getSelection().toString())
        else if e.which == 86 && e.metaKey
          @term.emit 'data', Clipboard.readText()

    @applyEditorStyling()
    @handleEvents()

    ipc.send 'connection-state-request'

  applyEditorStyling: ->
    @term.element.style.height = '100%'
    @term.element.style.fontFamily = ->
      atom.config.get('editor.fontFamily') or "monospace"
    @term.element.style.fontSize = ->
      atom.config.get('editor.fontSize')
    @openColor = @term.element.style.color

  handleEvents: ->
    #@on 'focus', =>
      #@resizeTerminal()
    #@on 'mousedown', '.terminal-view-resize-handle', (e) =>
      #@resizeStarted(e)

    @term.on 'data', (data) =>
      ipc.send 'terminal-data', data

    @terminal.on 'terminal-message-received', (message) =>
      @term.write(utf8.decode(window.atob(message)))
      @openLab()

    @terminal.on 'raw-terminal-char-copy-received', (message) =>
      @term.write(message)

    @terminal.on 'raw-terminal-char-copy-done', () =>
      @openLab()

    @terminal.on 'terminal-session-closed', () =>
      @term.off 'data'
      @term.element.style.color = '#666'
      @term.cursorHidden = true

    @terminal.on 'terminal-session-opened', () =>
      @term.off 'data'
      @term.on 'data', (data) =>
        ipc.send 'terminal-data', data

      @term.element.style.color = this.openColor
      @term.cursorHidden = false

    ipc.on 'connection-state', (state) =>
      @terminal.updateConnectionState(state)

  openLab: ->
    if @openPath
      ipc.send 'terminal-data', 'learn open ' + @openPath.toString() + '\r'
      @openPath = null

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

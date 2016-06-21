{$, View} = require 'atom-space-pen-views'
utf8      = require 'utf8'
ipc       = require 'ipc'
Clipboard = require 'clipboard'
remote    = require 'remote'
Menu      = remote.require 'menu'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel learn-terminal', =>
      @div class: 'terminal-view-resize-handle'

  initialize: (state, terminal, openPath, isTerminalWindow) ->
    @term = terminal.term
    @terminal = terminal
    @isTerminalWindow = isTerminalWindow
    @panel = atom.workspace.addBottomPanel(item: this, visible: false, className: 'learn-terminal-view')
    @openPath = openPath

    @term.open(this.get(0))
    #@term.write('Connecting...\r')

    @$terminalEl = $(@term.element)

    ipc.on 'remote-open-event', (file) =>
      @term.blur()

    @applyEditorStyling()
    @handleEvents()

    ipc.send 'connection-state-request'

  applyEditorStyling: ->
    @term.element.style.height = '100%'
    @term.element.style.fontFamily = ->
      atom.config.get('editor.fontFamily') or "monospace"
    recentFontSize = atom.config.get('integrated-learn-environment.currentFontSize')
    @term.element.style.fontSize = recentFontSize + 'px'
    @openColor = @term.element.style.color

  handleEvents: ->
    #@on 'focus', =>
      #@resizeTerminal()
    #@on 'mousedown', '.terminal-view-resize-handle', (e) =>
      #@resizeStarted(e)

    @$terminalEl.on 'focus', (e) =>
      @term.focus()

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
        if !!process.platform.match(/^win/) and event? and event.altKey
          console.log 'Saved from alt key disaster!'
        else
          ipc.send 'terminal-data', data

      @term.element.style.color = this.openColor
      @term.cursorHidden = false

    ipc.on 'connection-state', (state) =>
      @terminal.updateConnectionState(state)

    atom.commands.add @element,
      'core:copy': => atom.commands.dispatch(@element, 'learn-ide:copy')
      'core:paste': => atom.commands.dispatch(@element, 'learn-ide:paste')
      'learn-ide:copy': => @copy()
      'learn-ide:paste': => @paste()
      'learn-ide:increase-font-size': => @increaseFontSize()
      'learn-ide:decrease-font-size': => @decreaseFontSize()
      'learn-ide:reset-font-size': => @resetFontSize()

  openLab: (path = @openPath)->
    if path
      ipc.send 'terminal-data', 'learn open ' + path.toString() + '\r'
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

  visibleRowCount: ->
    Math.floor(@$terminalEl.height() / @$terminalEl.children().height())

  increaseFontSize: ->
    currentFontSize = parseInt @$terminalEl.css 'font-size'
    return if @isTerminalWindow and currentFontSize > 16
    return if not @isTerminalWindow and currentFontSize > 24

    @changeFontSize currentFontSize + 2

  decreaseFontSize: ->
    currentFontSize = parseInt @$terminalEl.css 'font-size'
    return if currentFontSize < 10

    @changeFontSize currentFontSize - 2

  resetFontSize: ->
    defaultSize = atom.config.get('integrated-learn-environment.defaultFontSize')
    @changeFontSize defaultSize

  changeFontSize: (fontSize) ->
    @$terminalEl.css 'font-size', fontSize
    atom.config.set('integrated-learn-environment.currentFontSize', fontSize)
    @term.resize(@term.cols, @visibleRowCount())
    @term.focus()
    @$terminalEl.focus()

  copy: ->
    Clipboard.writeText(getSelection().toString())

  paste: ->
    text = Clipboard.readText().replace(/\n/g, "\r")

    if !!process.platform.match(/^win/)
      ipc.send 'terminal-data', text
    else
      @term.emit 'data', text

  toggle: (focus) ->
    if @panel.isVisible()
      @panel.hide()
    else
      @panel.show()

      if focus
        @term.focus()
        @$terminalEl.focus()

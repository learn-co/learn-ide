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

    ipc.on 'remote-open-event', (file) =>
      @term.blur()

    if !!process.platform.match(/darwin/)
      this.on 'keydown', (e) =>
        if (e.which == 187 || e.which == 189) && e.metaKey
          e.preventDefault()
          e.stopPropagation()
          @adjustTermFontSize(e.which)

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

    $('.terminal').on 'focus', (e) =>
      @term.focus()

    $('.terminal').on 'contextmenu', (e) =>
      e.preventDefault()
      @onContextMenu()

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
        if !!process.platform.match(/^win/) && event?
          if event.which == 67 && event.shiftKey && event.ctrlKey
            @copy()
          else if event.which == 86 && event.shiftKey && event.ctrlKey
            @paste()
          else if (event.which == 38 || event.which == 40) && event.altKey
            @adjustTermFontSize(event.which)
          else if event.altKey
            console.log 'Saved from alt key disaster!'
          else if (event.which == 187 || event.which == 189) && event.ctrlKey
            @adjustTermFontSize(event.which)
          else
            ipc.send 'terminal-data', data
        else
          ipc.send 'terminal-data', data

      @term.element.style.color = this.openColor
      @term.cursorHidden = false

    ipc.on 'connection-state', (state) =>
      @terminal.updateConnectionState(state)

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

  newTerminalRowCount: ->
    Math.floor($('.learn-terminal').height() / $('.terminal div').height())

  resizeTermForFontSizeChange: ->
    @term.resize(80, @newTerminalRowCount())

  adjustTermFontSize: (key) ->
    $termDiv = $('.terminal')
    currentFontSize = parseInt($('.terminal').css('font-size'))

    if key == 187 || key == 38
      if (!@isTerminalWindow && currentFontSize < 26) || (@isTerminalWindow && currentFontSize < 18)
        $termDiv.css('font-size', currentFontSize + 2)
    else if key == 189 || key == 40
      if currentFontSize > 8
        $termDiv.css('font-size', currentFontSize - 2)

    @resizeTermForFontSizeChange()
    @term.focus()
    $('.terminal').focus()

  copy: () ->
    Clipboard.writeText(getSelection().toString())

  paste: () ->
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
        $('.terminal').focus()

  onContextMenu: () ->
    Menu.buildFromTemplate(@contextMenuTemplate()).popup()

  contextMenuTemplate: () ->
    if !!process.platform.match(/^win/)
      [
        {
          label: 'Copy',
          accelerator: 'Shift+Ctrl+C',
          role: 'copy'
        },
        {
          label: 'Paste',
          accelerator: 'Shift+Ctrl+V',
          role: 'paste'
        }
      ]
    else
      [
        {
          label: 'Copy',
          accelerator: 'Cmd+C'
          role: 'copy'
        },
        {
          label: 'Paste',
          accelerator: 'Cmd+V'
          role: 'paste'
        }
      ]

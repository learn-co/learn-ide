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

    @$termEl = $(@term.element)

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
    @on 'focus', => @fitTerminal()
    @on 'mousedown', '.terminal-view-resize-handle', (e) => @resizeStarted(e)

    @$termEl.on 'focus', (e) => @term.focus()
    @$termEl.on 'blur', (e) => @onBlur(e)

    @term.on 'data', (data) -> ipc.send 'terminal-data', data

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

    @terminal.on 'terminal-session-opened', =>
      @fitTerminal()
      @term.off 'data'
      @term.on 'data', (data) ->
        # TODO: handle non-darwin copy/paste shortcut in keymaps
        {ctrlKey, shiftKey, which} = event if event
        if process.platform isnt 'darwin' and event and ctrlKey and shiftKey
          atom.commands.dispatch(@element, 'learn-ide:copy') if which is 67
          atom.commands.dispatch(@element, 'learn-ide:paste') if which is 86
        else
          ipc.send 'terminal-data', data
      @term.element.style.color = this.openColor
      @term.cursorHidden = false

    ipc.on 'connection-state', (state) =>
      @terminal.updateConnectionState(state)

    atom.commands.onDidDispatch (e) => @updateFocus(e)

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

  onBlur: (e) ->
    {relatedTarget} = e
    @unfocus() if relatedTarget? and relatedTarget isnt @term.element

  updateFocus: (e) ->
    if document.activeElement is @term.element then @focus() else @unfocus()

  resizeStarted: ->
    $(document).on('mousemove', @resize)
    $(document).on('mouseup', @resizeStopped)

  resizeStopped: =>
    $(document).off('mousemove', @resize)
    $(document).off('mouseup', @resizeStopped)
    @fitTerminal()

  resize: ({pageY, which}) =>
    return @resizeStopped() unless which is 1

    newHeight = @outerHeight() + @offset().top - pageY
    return if newHeight < 100

    @height(newHeight)

  fitTerminal: ->
    @term.fit() if @panel.isVisible()

  currentFontSize: ->
    parseInt @$termEl.css 'font-size'

  increaseFontSize: ->
    currentFontSize = @currentFontSize()
    return if @isTerminalWindow and currentFontSize > 16
    return if not @isTerminalWindow and currentFontSize > 24

    @changeFontSize currentFontSize + 2

  decreaseFontSize: ->
    currentFontSize = @currentFontSize()
    return if currentFontSize < 10

    @changeFontSize currentFontSize - 2

  resetFontSize: ->
    defaultSize = atom.config.get('integrated-learn-environment.defaultFontSize')
    @changeFontSize defaultSize

  persistFontSize: (fontSize = @currentFontSize()) ->
    atom.config.set('integrated-learn-environment.currentFontSize', fontSize)

  changeFontSize: (fontSize) ->
    @$termEl.css 'font-size', fontSize
    @persistFontSize fontSize
    @fullFocus()

  unfocus: ->
    @blur()
    @term.blur()

  transferFocus: ->
    @unfocus()
    atom.workspace.getActivePane().activate()

  hasFocus: ->
    @$termEl.is(':focus') or document.activeElement is @term.element

  toggleFocus: ->
    if @hasFocus()
      @transferFocus()
    else
      @fullFocus()

  fullFocus: ->
    @fitTerminal()
    @term.focus()
    @$termEl.focus()

  copy: ->
    Clipboard.writeText(getSelection().toString().replace(/\u00A0/g, ' '))

  paste: ->
    text = Clipboard.readText().replace(/\n/g, '\r')

    if process.platform isnt 'darwin'
      ipc.send 'terminal-data', text
    else
      @term.emit 'data', text

  toggle: () ->
    return @panel.hide() if @panel.isVisible()

    @panel.show()
    @fullFocus()

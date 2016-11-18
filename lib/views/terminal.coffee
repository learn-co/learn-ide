{$, View} = require 'atom-space-pen-views'
Clipboard = require 'clipboard'
remote    = require 'remote'
Menu      = remote.require 'menu'
TerminalWrapper = require './terminal-wrapper'
localStorage = require '../local-storage'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'panel learn-terminal', =>
      @div class: 'terminal-view-resize-handle'

  initialize: (terminal, openPath, isTerminalWindow) ->
    @terminal = terminal
    @isTerminalWindow = isTerminalWindow

    rows = if isTerminalWindow then 26 else 18
    @terminalWrapper = new TerminalWrapper(cols: 80, rows: rows, useStyle: no, screenKeys: no, scrollback: yes)
    window.term = @terminalWrapper
    @panel = atom.workspace.addBottomPanel(item: this, visible: false, className: 'learn-terminal-view')
    @openPath = openPath

    @terminalWrapper.open(this.get(0))

    @$termEl = $(@terminalWrapper.element)

    @applyEditorStyling()
    @handleEvents()
    @terminalWrapper.restore()
    @terminalWrapper.showCursor()

    if @isTerminalWindow
      document.getElementsByClassName('terminal-view-resize-handle')[0].setAttribute('style', 'display:none;')
      # document.getElementsByClassName('inset-panel')[0].setAttribute('style', 'display:none;')
      document.getElementsByClassName('learn-terminal')[0].style.height = '448px'
      workspaceView = atom.views.getView(atom.workspace)
      atom.commands.dispatch(workspaceView, 'tree-view:toggle')

  applyEditorStyling: ->
    fontSize = localStorage.get('learn-ide:currentFontSize')
    fontSize ?= atom.config.defaultSettings.editor.fontSize
    @terminalWrapper.element.style.height = '100%'
    @terminalWrapper.element.style.fontFamily = -> atom.config.get('editor.fontFamily') or "monospace"
    @terminalWrapper.element.style.fontSize = "#{fontSize}px"
    @openColor = atom.config.get('learn-ide.terminalFontColor')
    @openBackgroundColor = atom.config.get('learn-ide.terminalBackgroundColor')

  displayDisconnected: ->
    @terminalWrapper.off 'data'
    @terminalWrapper.element.style.color = '#666'
    @terminalWrapper.cursorHidden = true
    @terminalWrapper.write('Unable to connect to Learn\r')

  handleEvents: ->
    @on 'focus', => @fitTerminal()
    @on 'mousedown', '.terminal-view-resize-handle', (e) => @resizeStarted(e)

    @$termEl.on 'focus', (e) => @terminalWrapper.focus()
    @$termEl.on 'blur', (e) => @onBlur(e)

    @terminalWrapper.on 'data', (data) =>
      @terminal.send(data)

    @terminal.on 'message', (message) =>
      @terminalWrapper.write(message)

    @terminal.on 'close', () =>
      @displayDisconnected()

    @terminal.on 'error', () =>
      @displayDisconnected()

    @terminal.on 'open', =>
      @fitTerminal()
      @terminalWrapper.off 'data'
      self = @
      @terminalWrapper.on 'data', (data) ->
        # TODO: handle non-darwin copy/paste shortcut in keymaps
        {ctrlKey, shiftKey, which} = event if event
        if process.platform isnt 'darwin' and event and ctrlKey and shiftKey
          atom.commands.dispatch(@element, 'learn-ide:copy') if which is 67
          atom.commands.dispatch(@element, 'learn-ide:paste') if which is 86
        else
          self.terminal.send data
      @terminalWrapper.element.style.color = @openColor
      @terminalWrapper.element.style.backgroundColor = @openBackgroundColor
      @terminalWrapper.cursorHidden = false

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
      @terminal.send('learn open ' + path.toString() + '\r')
      @openPath = null

  onBlur: (e) ->
    {relatedTarget} = e
    @unfocus() if relatedTarget? and relatedTarget isnt @terminalWrapper.element

  updateFocus: (e) ->
    if document.activeElement is @terminalWrapper.element then @focus() else @unfocus()

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
    @terminalWrapper.fit() if @panel.isVisible()

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
    defaultSize = atom.config.defaultSettings.editor.fontSize
    @changeFontSize defaultSize

  persistFontSize: (fontSize = @currentFontSize()) ->
    localStorage.set('learn-ide:currentFontSize', fontSize)

  changeFontSize: (fontSize) ->
    @$termEl.css 'font-size', fontSize
    @persistFontSize fontSize
    @fullFocus()

  unfocus: ->
    @blur()
    @terminalWrapper.blur()

  transferFocus: ->
    @unfocus()
    atom.workspace.getActivePane().activate()

  hasFocus: ->
    @$termEl.is(':focus') or document.activeElement is @terminalWrapper.element

  toggleFocus: ->
    if @hasFocus()
      @transferFocus()
    else
      @fullFocus()

  fullFocus: ->
    @fitTerminal()
    @terminalWrapper.focus()
    @$termEl.focus()

  copy: ->
    Clipboard.writeText(getSelection().toString().replace(/\u00A0/g, ' '))

  paste: ->
    text = Clipboard.readText().replace(/\n/g, '\r')

    if process.platform isnt 'darwin'
      @terminal.send text
    else
      @terminalWrapper.emit 'data', text

  showAndFocus: ->
    @panel.show()
    @fullFocus()

  toggle: ->
    if @panel.isVisible()
      @panel.hide()
    else
      @showAndFocus()


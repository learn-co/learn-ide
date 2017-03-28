{$, View} = require 'atom-space-pen-views'
{clipboard} = require 'electron'
TerminalEmulator = require 'xterm'
TerminalEmulator.loadAddon 'fit'

module.exports =
class TerminalView extends View
  @content: ->
    @div class: 'terminal-resizer tool-panel', =>
      @div class: 'terminal-resize-handle', outlet: 'resizeHandle'
      @div class: 'emulator-container', outlet: 'emulatorContainer'

  initialize: (@terminal) ->
    @emulator = new TerminalEmulator({cursorBlink: true})
    @subscribe()
    @attach()

  subscribe: ->
    @emulator.on 'data', (data) =>
      if not event?
        @terminal.send(data)
      else
        @parseTerminalDataEvent(event, data)

    @terminal.on 'message', (msg) =>
      @emulator.write(msg)

    @on 'mousedown', '.terminal-resize-handle', (e) =>
      @resizeByDragStarted(e)

  parseTerminalDataEvent: ({which, ctrlKey, shiftKey}, data) ->
    if not ctrlKey or process.platform is 'darwin'
      @terminal.send(data)
      return

    if shiftKey and which is 67
      # ctrl-C
      atom.commands.dispatch(@element, 'core:copy')
      return

    if shiftKey and which is 86
      # ctrl-V
      atom.commands.dispatch(@element, 'core:paste')
      return

    if which is 83
      # ctrl-s
      view = atom.views.getView(atom.workspace)
      atom.commands.dispatch(view, 'learn-ide:save')
      return

    @terminal.send(data)

  attach: ->
    atom.workspace.addBottomPanel({item: this})
    @emulator.open(@emulatorContainer[0])

  copyText: ->
    selection = document.getSelection()
    rawText = selection.toString()
    preparedText = rawText.replace(/\u00A0/g, ' ').replace(/\s+(\n)?$/gm, '$1')

    clipboard.writeText(preparedText)

  pasteText: ->
    rawText = clipboard.readText()
    preparedText = rawText.replace(/\n/g, '\r')

    @terminal.send(preparedText)

  toggleFocus: ->
    hasFocus = document.activeElement is @emulator.textarea

    if hasFocus then @transferFocus() else @focusEmulator()

  transferFocus: ->
    atom.workspace.getActivePane().activate()

  focusEmulator: ->
    @emulator.focus()

  currentFontSize: ->
    $el = $(@emulator.element)
    parseInt($el.css('font-size'))

  increaseFontSize: ->
    @setFontSize(@currentFontSize() + 2)

  decreaseFontSize: ->
    currentSize = @currentFontSize()

    if currentSize > 2
      @setFontSize(currentSize - 2)

  resetFontSize: ->
    defaultSize = atom.config.defaultSettings.editor.fontSize
    @setFontSize(defaultSize)

  setFontSize: (size) ->
    $(@emulator.element).css('font-size', size)
    @resizeTerminal()

  resizeByDragStarted: =>
    $(document).on('mousemove', @resizeAfterDrag)
    $(document).on('mouseup', @resizeByDragStopped)

  resizeByDragStopped: =>
    $(document).off('mousemove', @resizeAfterDrag)
    $(document).off('mouseup', @resizeByDragStopped)

  resizeAfterDrag: ({pageY, which}) =>
    if which isnt 1
      return @resizeByDragStopped()

    height = @outerHeight() + @offset().top - pageY

    if height > 100
      @resizeTerminal(height)

  resizeTerminal: (height = @height()) ->
    # resize container and fit emulator inside it
    @emulatorContainer.height(height - @resizeHandle.height())
    @emulator.fit()

    # then get emulator height and fit containers around it
    rowHeight = parseInt(@emulator.rowContainer.style.lineHeight)
    newHeight = rowHeight * @emulator.rows
    @emulatorContainer.height(newHeight)
    @height(newHeight + @resizeHandle.height())


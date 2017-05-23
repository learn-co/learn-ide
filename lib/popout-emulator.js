var bus = require('./event-bus')
var localStore = require('./local-storage')
var TerminalEmulator = require('xterm')
var {clipboard} = require('electron')

TerminalEmulator.loadAddon('fit')
TerminalEmulator.loadAddon('fullscreen')

class PopoutEmulator {
  constructor() {
    this.style = document.createElement('style')
    this.emulator = new TerminalEmulator({cursorBlink: true})

    this.attach()
    this.subscribe()
    this.clearScreen()
  }

  attach() {
    this.style.innerHTML = localStore.remove('popout-emulator:css')
    document.head.appendChild(this.style)

    document.body.style.height = `${window.innerHeight}px`
    document.body.style.fontSize = `${localStore.get('popout-emulator:font-size')}px`
    this.emulator.open(document.body)

    this.emulator.toggleFullscreen(true)
    this.emulator.fit()
  }

  get container() {
    return this.emulator.parent
  }

  subscribe() {
    this.emulator.attachCustomKeydownHandler((e) => {
      this.handleShortcuts(e)
    })

    this.emulator.on('data', (data) => {
      this.sendToTerminal(data)
    })

    bus.on('popout-emulator:write', (text) => {
      this.emulator.write(text)
    })

    window.onresize = () => {
      this.container.style.height = `${window.innerHeight}px`
      this.emulator.fit()
    }
  }

  clearScreen() {
    this.sendToTerminal('')
  }

  sendToTerminal(data) {
    bus.emit('popout-emulator:data', data)
  }

  handleShortcuts(e) {
    var wasHandled = false
    var {which, metaKey, shiftKey, ctrlKey} = e

    if ((process.platform === 'darwin') && metaKey) {
      wasHandled = this.handleCommandKey(which)
    }

    if ((process.platform !== 'darwin') && ctrlKey) {
      wasHandled = this.handleCtrlKey(which, shiftKey)
    }

    if (wasHandled) { event.preventDefault() }
  }

  handleCommandKey(which) {
    if (which === 187) {
      // cmd-=
      this.increaseFontSize()
      return true
    }

    if (which === 189) {
      // cmd--
      this.decreaseFontSize()
      return true
    }

    if (which === 48) {
      // cmd-0
      this.resetFontSize()
      return true
    }

    if (which === 67) {
      // cmd-c
      this.clipboardCopy()
      return true
    }

    if (which === 86) {
      // cmd-v
      this.clipboardPaste()
      return true
    }

    return false
  }

  handleCtrlKey(which, shiftKey) {
    if (which === 187) {
      // cmd-=
      this.increaseFontSize()
      return true
    }

    if (which === 189) {
      // cmd--
      this.decreaseFontSize()
      return true
    }

    if (which === 48) {
      // cmd-0
      this.resetFontSize()
      return true
    }

    if (shiftKey && (which === 67)) {
      // ctrl-C
      this.clipboardCopy()
      return true
    }

    if (shiftKey && (which === 86)) {
      // ctrl-V
      this.clipboardPaste()
      return true
    }

    return false
  }

  clipboardCopy() {
    var selection = document.getSelection();
    var rawText = selection.toString();
    var preparedText = rawText.replace(/\u00A0/g, ' ').replace(/\s+(\n)?$/gm, '$1');

    clipboard.writeText(preparedText);
  }

  clipboardPaste() {
    var rawText = clipboard.readText();
    var preparedText = rawText.replace(/\n/g, '\r');

    this.sendToTerminal(preparedText)
  }

  fontSize() {
    var style = window.getComputedStyle(this.container),
        size = parseInt(style.fontSize);

    if (this.initialFontSize == null) { this.initialFontSize = size }

    return size
  }

  increaseFontSize() {
    this.setFontSize(this.fontSize() + 2)
  }

  decreaseFontSize() {
    var next = this.fontSize() - 2;
    if (next < 2) { return }
    this.setFontSize(next)
  }

  resetFontSize() {
    if (this.initialFontSize == null) { return }
    this.setFontSize(this.initialFontSize)
  }

  setFontSize(sizeInt) {
    this.container.style.fontSize = `${sizeInt}px`

    // Two calls are necessary to properly fit after the font-size has changed
    this.emulator.fit()
    this.emulator.fit()
  }
}

var popout = new PopoutEmulator()


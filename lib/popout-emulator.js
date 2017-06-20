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
      if (this.shortcutHandled(e)) {
        e.preventDefault()
        return false
      }
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

  shortcutHandled({keyCode, metaKey, shiftKey, ctrlKey}) {
    var wasHandled = false;

    if ((process.platform === 'darwin') && metaKey) {
      wasHandled = this.handleCommandKey(keyCode)
    }

    if ((process.platform !== 'darwin') && ctrlKey) {
      wasHandled = this.handleCtrlKey(keyCode, shiftKey)
    }

    return wasHandled
  }

  handleCommandKey(keyCode) {
    if (keyCode === 187) {
      // cmd-=
      this.increaseFontSize()
      return true
    }

    if (keyCode === 189) {
      // cmd--
      this.decreaseFontSize()
      return true
    }

    if (keyCode === 48) {
      // cmd-0
      this.resetFontSize()
      return true
    }

    if (keyCode === 38) {
      // cmd-up
      this.scrollUp()
      return true
    }

    if (keyCode === 40) {
      // cmd-down
      this.scrollDown()
      return true
    }

    if (keyCode === 67) {
      // cmd-c
      this.clipboardCopy()
      return true
    }

    if (keyCode === 86) {
      // cmd-v
      this.clipboardPaste()
      return true
    }

    return false
  }

  handleCtrlKey(keyCode, shiftKey) {
    if (keyCode === 187) {
      // ctrl-=
      this.increaseFontSize()
      return true
    }

    if (keyCode === 189) {
      // ctrl--
      this.decreaseFontSize()
      return true
    }

    if (keyCode === 48) {
      // ctrl-0
      this.resetFontSize()
      return true
    }

    if (keyCode === 38) {
      // ctrl-up
      this.scrollUp()
      return true
    }

    if (keyCode === 40) {
      // ctrl-down
      this.scrollDown()
      return true
    }

    if (shiftKey && (keyCode === 67)) {
      // ctrl-C
      this.clipboardCopy()
      return true
    }

    if (shiftKey && (keyCode === 86)) {
      // ctrl-V
      this.clipboardPaste()
      return true
    }

    return false
  }

  scrollUp() {
    this.emulator.scrollDisp(-1);
  }

  scrollDown() {
    this.emulator.scrollDisp(1);
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


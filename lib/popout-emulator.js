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
    let css = localStore.remove('popout-emulator:css') +
              localStore.remove('popout-emulator:xterm-css') +
              localStore.remove('popout-emulator:fullscreen-css');

    this.style.innerHTML = css
    document.head.appendChild(this.style)

    document.body.style.height = `${window.innerHeight}px`
    document.body.style.fontSize = `${localStore.get('popout-emulator:font-size')}px`
    this.emulator.open(document.body, true)

    this.emulator.toggleFullscreen(true)
    this.setFontFamily(localStore.get('popout-emulator:font-family'))
  }

  get container() {
    return this.emulator.parent
  }

  subscribe() {
    this.emulator.attachCustomKeydownHandler((e) => {
      var callbackName = this.callbackNameForKeyEvent(e);

      if (callbackName != null) {
        e.preventDefault()
        this[callbackName](e)
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

  callbackNameForKeyEvent({keyCode, metaKey, shiftKey, ctrlKey}) {
    var keyCodeCallbacks = {
      // Mac only
        cmd: {
          187: 'increaseFontSize', // cmd-=
          189: 'decreaseFontSize', // cmd--
          48: 'resetFontSize',     // cmd-0
          38: 'scrollUp',          // cmd-up
          40: 'scrollDown',        // cmd-down
          67: 'clipboardCopy',     // cmd-c
          86: 'clipboardPaste'     // cmd-v
        },
      // Windows & Linux only
        ctrl: {
          187: 'increaseFontSize', // ctrl-=
          189: 'decreaseFontSize', // ctrl--
          48: 'resetFontSize',     // ctrl-0
          38: 'scrollUp',          // ctrl-up
          40: 'scrollDown'         // ctrl-down
        },
        ctrlShift: {
          67: 'clipboardCopy',     // ctrl-C
          86: 'clipboardPaste'     // ctrl-V
        }
      }

    var isMac = process.platform === 'darwin';

    var callbackGroup;
    if (isMac && metaKey) {
      callbackGroup = keyCodeCallbacks.cmd
    } else if (!isMac && ctrlKey) {
      callbackGroup = shiftKey ? keyCodeCallbacks.ctrlShift : keyCodeCallbacks.ctrl
    }

    if (!callbackGroup) { return }

    return callbackGroup[keyCode]
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
    this.fit()
  }

  setFontFamily(fontFamily) {
    if (fontFamily && fontFamily.length) {
      this.emulator.element.style.fontFamily = fontFamily
      this.fit()
    }
  }

  fit() {
    // Two calls are necessary to properly fit
    this.emulator.fit()
    this.emulator.fit()
  }
}

var popout = new PopoutEmulator()


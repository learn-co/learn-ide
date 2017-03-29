var bus = require('./event-bus')
var localStore = require('./local-storage')
var TerminalEmulator = require('xterm')

TerminalEmulator.loadAddon('fit')
TerminalEmulator.loadAddon('fullscreen')

class PopoutEmulator {
  constructor(containerID) {
    this.style = document.createElement('style')
    this.emulator = new TerminalEmulator({cursorBlink: true})
    this.container = document.getElementById(containerID)

    this.attach()
    this.subscribe()
    this.clearScreen()
  }

  attach() {
    this.style.innerHTML = localStore.remove('popout-emulator:css')
    document.head.appendChild(this.style)

    this.emulator.open(this.container)
    this.emulator.toggleFullscreen(true)
  }

  subscribe() {
    this.emulator.on('data', (data) => {
      bus.emit('popout-emulator:data', data)
    })

    bus.on('popout-emulator:write', (text) => {
      this.emulator.write(text)
    })

    window.onresize = () => this.emulator.fit()
  }

  clearScreen() {
    bus.emit('popout-emulator:data', '')
  }
}

var popout = new PopoutEmulator('terminal')


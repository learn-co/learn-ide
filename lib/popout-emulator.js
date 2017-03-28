var bus = require('./event-bus')
var localStorage = require('./local-storage')
var TerminalEmulator = require('xterm')

TerminalEmulator.loadAddon('fit')
TerminalEmulator.loadAddon('fullscreen')

class PopoutEmulator {
  constructor(containerID) {
    this.container = document.getElementById(containerID)
    this.emulator = new TerminalEmulator({cursorBlink: true})

    this.attach()
    this.subscribe()
    this.clearScreen()
  }

  attach() {
    this.emulator.open(this.container)
    this.emulator.toggleFullscreen()
  }

  subscribe() {
    this.emulator.on('data', (data) => {
      bus.emit('popout-emulator:data', data)
    })

    bus.on('popout-emulator:write', (text) => {
      this.emulator.write(text)
    })
  }

  clearScreen() {
    bus.emit('popout-emulator:data', '')
  }
}

var emulator = new PopoutEmulator('terminal')


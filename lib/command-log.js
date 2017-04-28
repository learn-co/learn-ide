'use babel'

import localStorage from './local-storage'

const key = 'learn-ide:recent-commands';

export default {
  get() {
    var commands = JSON.parse(localStorage.get(key)) || [];

    return commands;
  },

  add(command) {
    var commands = this.get();

    if (commands.unshift(command) > 5) { commands.pop() }

    localStorage.set(key, JSON.stringify(commands))
  }
}


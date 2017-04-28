'use babel'

import log from './log'
import commandLog from './command-log'

function hostIP() {
  return LEARN_IDE_HOST_IP
}

function clearHostIP() {
  LEARN_IDE_HOST_IP = null
}

export default function monitor(terminal, subscriptions) {
  subscriptions.add(atom.commands.onDidDispatch(({type}) => {
    commandLog.add(type)
  }))

  subscriptions.add(atom.onDidThrowError(({message, url, line, column}) => {
    var location = `${url}:${line}:${column}`
    log.add({event: 'error', location, message})
  }))

  terminal.on('open', () => {
    var ipPromise = terminal.getHostIp()

    ipPromise.then(ip => window.LEARN_IDE_HOST_IP = ip)

    log.add({event: 'ws_open'}).then(({id}) => {
      ipPromise.then(host_ip => log.update(id, {host_ip}))
    })
  })

  terminal.on('error', () => {
    log.add({event: 'ws_error', host_ip: hostIP()})
  })

  terminal.on('close', ({reason, code}) => {
    log.add({event: 'ws_close', host_ip: hostIP(), reason, code})
    clearHostIP()
  })
}

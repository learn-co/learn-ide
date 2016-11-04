winston = require 'winston'
path = require 'path'

logfile = path.join(atom.getConfigDirPath(), 'learn-ide.log')

logger = new (winston.Logger)({
  transports: [
    new (winston.transports.File)({
      filename: logfile
      level: 'info'
    })
  ]
})

module.exports = logger

'use babel'

import path from 'path'
import dotenv from 'dotenv'

dotenv.config({
  path: path.join(__dirname, '..', '.env'),
  silent: true
});

dotenv.config({
  path: path.join(atom.getConfigDirPath(), '.env'),
  silent: true
});

const util = {
  defaultConfig: {
    host: 'ide.learn.co',
    port: 443,
    path: 'socket',
    learnCo: 'https://learn.co'
  },

  envConfig() {
    return this.clean({
      host: process.env['IDE_WS_HOST'],
      port: process.env['IDE_WS_PORT'],
      path: process.env['IDE_WS_TERM_PATH'],
      learnCo: process.env['IDE_LEARN_CO'],
      airbrakeEnabled: this.airbrakeEnabled()
    })
  },

  airbrakeEnabled() {
    if (process.env['AIRBRAKE_ENABLED'] === 'true') { return true }
    if (process.env['AIRBRAKE_ENABLED'] === 'false') { return false }
  },

  clean(obj) {
    var cleanObj = {};

    Object.keys(obj).forEach((key) => {
      if (obj[key] != null) { cleanObj[key] = obj[key] }
    })

    return cleanObj;
  }
}

export default { ...util.defaultConfig, ...util.envConfig() }


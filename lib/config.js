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

var defaultConfig = {
  host: 'ile.learn.co',
  port: 443,
  path: 'v2/terminal',
  learnCo: 'https://learn.co'
}

var envConfig = {
  host: process.env['IDE_WS_HOST'],
  port: process.env['IDE_WS_PORT'],
  path: process.env['IDE_WS_TERM_PATH'],
  learnCo: process.env['IDE_LEARN_CO']
}

export default Object.assign({}, defaultConfig, clean(envConfig))

function clean(obj) {
  var cleanObj = {};

  Object.keys(obj).forEach((key) => {
    if (obj[key] != null) { cleanObj[key] = obj[key] }
  })

  return cleanObj;
}

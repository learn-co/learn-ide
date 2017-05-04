'use babel'

import {app} from 'remote'
import commandLog from './command-log'
import {learnCo} from './config'
import path from 'path'
import post from './post'
import token from './token'
import {name, version} from './application-metadata'

var appVersion = (() => name.includes('atom') ? version : window.LEARN_IDE_VERSION)()

function rootDirectory(stack) {
  var pkgPath = path.resolve(__dirname, '..');

  if (stack.match(pkgPath) === null) { return }

  return pkgPath;
}

function backtrace(rawStack=[]) {
  return rawStack.map((entry) => {
    return {
      file: entry.getFileName(),
      line: entry.getLineNumber(),
      column: entry.getColumnNumber(),
      function: entry.getFunctionName()
    };
  });
}

function payload(err) {
  return {
    error: {
      message: err.message,
      type: err.name,
      backtrace: backtrace(err.getRawStack())
    },
    context: {
      environment: name,
      os: process.platform,
      version: appVersion,
      rootDirectory: rootDirectory(err.stack)
    },
    additional: {
      commands: commandLog.get(),
      learn_ide_package_version: version,
      occurred_at: Date.now(),
      os_detail: navigator.platform,
      stack: err.stack,
      token: token.get()
    }
  };
}

export default {
  notify(err) {
    var url = `${learnCo}/api/v1/learn_ide_airbrake`;

    return post(url, payload(err), {'Authorization': `Bearer ${token.get()}`});
  }
}


'use babel'

import {app} from 'remote'
import commandLog from './command-log'
import {learnCo} from './config'
import path from 'path'
import post from './post'
import token from './token'
import {parse} from 'stacktrace-parser'
import {name, version} from './application-metadata'

var appVersion = (() => name.includes('atom') ? version : window.LEARN_IDE_VERSION)();

function rootDirectory(stack) {
  var pkgPath = path.resolve(__dirname, '..');

  if (stack.match(pkgPath) === null) { return }

  return pkgPath;
}

function backtrace(stack='') {
  return parse(stack).map((entry) => {
    return {
      file: entry.file,
      line: entry.lineNumber,
      column: entry.column,
      function: entry.methodName
    };
  });
}

function payload(err) {
  return {
    error: {
      message: err.message,
      type: err.name,
      backtrace: backtrace(err.stack)
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


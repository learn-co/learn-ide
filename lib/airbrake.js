'use babel'

import commandLog from './command-log'
import path from 'path'
import post from './post'
import remote from 'remote'
import token from './token'
import {learnCo, airbrakeEnabled} from './config'
import {name, version} from './application-metadata'
import {parse} from 'stacktrace-parser'

const fs = remote.require('fs-plus')

const util = {
  pkgPath() {
    return path.resolve(__dirname, '..')
  },

  shouldNotify() {
    if (airbrakeEnabled != null) { return airbrakeEnabled }

    // package is symlinked to ~/.atom/packages, likely for dev purposes
    var isProbablyDevelopmentPackage = fs.isSymbolicLinkSync(this.pkgPath())

    return !isProbablyDevelopmentPackage
  },

  appVersion() {
    return name.includes('atom') ? version : window.LEARN_IDE_VERSION
  },

  backtrace(stack='') {
    return parse(stack).map((entry) => {
      return {
        file: entry.file,
        line: entry.lineNumber,
        column: entry.column,
        function: entry.methodName
      };
    });
  },

  rootDirectory(stack) {
    if (stack.match(this.pkgPath()) === null) { return }

    return this.pkgPath();
  },

  payload(err) {
    return {
      error: {
        message: err.message,
        type: err.name,
        backtrace: this.backtrace(err.stack)
      },
      context: {
        environment: name,
        os: process.platform,
        version: this.appVersion(),
        rootDirectory: this.rootDirectory(err.stack)
      },
      additional: {
        commands: commandLog.get(),
        core_app_version: version,
        package_version: window.LEARN_IDE_VERSION,
        occurred_at: Date.now(),
        os_detail: navigator.platform,
        token: token.get()
      }
    }
  }
}

export default {
  notify(err) {
    var url = `${learnCo}/api/v1/learn_ide_airbrake`;

    if (!util.shouldNotify()) {
      console.warn(`*Airbrake notification will not be sent for "${err.message}"`)
      return Promise.resolve()
    }

    return post(url, util.payload(err), {'Authorization': `Bearer ${token.get()}`});
  }
}


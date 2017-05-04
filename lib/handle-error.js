'use babel'

/*
 * This handler was lifted directly from the learn-ide-notifications package.
 * As there can only be one `atom.onWillThrowError` callback, we want to manage
 * it from our primary package.
 */

import remote from 'remote';
import {parse} from 'stacktrace-parser';

const fs = remote.require('fs-plus');

function isCoreOrPackageStackTrace(stack='') {
  return parse(stack).some((entry) => fs.isAbsolute(entry.file))
};

export default function({message, url, line, originalError, preventDefault}) {
  var match;

  if (originalError.name === 'BufferedProcessError') {
    message = message.replace('Uncaught BufferedProcessError: ', '');
    atom.notifications.addError(message, {dismissable: true});

  } else if ((originalError.code === 'ENOENT') && !/\/atom/i.test(message) && (match = /spawn (.+) ENOENT/.exec(message))) {
    message = `'${match[1]}' could not be spawned. Is it installed and on your path? If so please open an issue on the package spawning the process.`;
    atom.notifications.addError(message, {dismissable: true});

  } else if (!atom.inDevMode() || atom.config.get('notifications.showErrorsInDevMode')) {
    preventDefault();

    // Ignore errors with no paths in them since they are impossible to trace
    if (originalError.stack && !isCoreOrPackageStackTrace(originalError.stack)) {
      return;
    }

    var options = {
      detail: `${url}:${line}`,
      stack: originalError.stack,
      dismissable: true
    };

    atom.notifications.addFatalError(message, options);
  }
};

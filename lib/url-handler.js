'use babel'

import url from 'url'
import {ipcRenderer} from 'electron'
import localStorage from './local-storage'
import bus from './event-bus'

function getLabSlug() {
  var {urlToOpen} = JSON.parse(decodeURIComponent(location.hash.substr(1)));
  return url.parse(urlToOpen).pathname.substring(1);
};

function openInNewWindow() {
  localStorage.set('learnOpenLabOnActivation', getLabSlug());
  ipcRenderer.send('command', 'application:new-window');
};

function openInExistingWindow() {
  bus.emit('learn:open', {timestamp: Date.now(), slug: getLabSlug()})
}

function windowOpen() {
  return localStorage.get('lastFocusedWindow')
}

function onWindows() {
  return process.platform === 'win32'
}

export default function() {
  if (!windowOpen() || onWindows()) {
    openInNewWindow();
  } else {
    openInExistingWindow();
  }

  return Promise.resolve();
};

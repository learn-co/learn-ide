'use babel'

import url from 'url'
import {ipcRenderer} from 'electron'
import localStorage from './local-storage'

function getLabSlug() {
  let {urlToOpen} = JSON.parse(decodeURIComponent(location.hash.substr(1)));
  return url.parse(urlToOpen).pathname.substring(1);
}

function openLab(labSlug) {
  localStorage.set('learnOpenLabOnActivation', labSlug);
  ipcRenderer.send('command', 'application:new-window');
}

export default function() {
  openLab(getLabSlug());
  return Promise.resolve();
}

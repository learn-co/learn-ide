'use babel'

import atomHelper from './atom-helper'
import localStorage from './local-storage'
import token from './token'
import {BrowserWindow} from 'remote'
import {learnCo} from './config'

function logOutOfLearn() {
  var win = new BrowserWindow({show: false});

  return new Promise((resolve) => {
    win.once('ready-to-show', resolve);
    win.loadURL(`${learnCo}/sign_out`);
  });
}

function logOutOfGithub() {
  if (localStorage.remove('didCompleteGithubLogin') === null) {
    return Promise.resolve()
  }

  var win = new BrowserWindow({autoHideMenuBar: true, show: false});

  return new Promise((resolve) => {
    win.once('ready-to-show', () => win.show());

    win.webContents.on('will-navigate', () => win.hide());

    win.webContents.on('did-navigate', (e, url) => {
      console.log('URL:', url)
      if (url.endsWith('github.com/')) { resolve() }
    });

    win.loadURL('https://github.com/logout');
  });
}

export default function logout() {
  token.unset();

  learn = logOutOfLearn()
  github = logOutOfGithub()

  var promises = [learn, github]
  window.promises = promises

  return Promise.all([learn, github]).then(() => {
    atomHelper.emit('learn-ide:logout');
    atomHelper.closePaneItems();
    atom.restartApplication();
  });
}

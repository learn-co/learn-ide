'use babel'

import _token from './token';
import username from './username';
import _url from 'url';
import fetch from './fetch';
import localStorage from './local-storage';
import shell from 'shell';
import {BrowserWindow} from 'remote';
import {learnCo} from './config';
import {version} from '../package.json';

var authUrl = `${learnCo}/api/v1/learn_ide/authenticate?version=${version}`;

function confirmOauthToken(token) {
  var headers = new Headers({'Authorization': `Bearer ${token}`});

  return fetch(authUrl, {headers}).then(function(data) {
    username.set(data.username)
    return (data.email != null) ? data : false
  });
}

function githubLogin() {
  return new Promise((resolve, reject) => {
    var win = new BrowserWindow({autoHideMenuBar: true, show: false, width: 440, height: 660, resizable: false});
    var { webContents } = win;

    win.setSkipTaskbar(true);
    win.setMenuBarVisibility(false);
    win.setTitle('Sign in to Github to get started with the Learn IDE');

    // show window only if login is required
    webContents.on('did-finish-load', () => win.show());

    // hide window immediately after login
    webContents.on('will-navigate', (e, url) => {
      if (url.match(`${learnCo}/users/auth/github/callback`)) { return win.hide(); }
    });

    webContents.on('did-get-redirect-request', (e, oldURL, newURL) => {
      if (!newURL.match(/ide_token/)) { return; }

      var token = _url.parse(newURL, true).query.ide_token;

      confirmOauthToken(token).then((res) => {
        if (res == null) { return; }

        localStorage.set('didCompleteGithubLogin');
        _token.set(token);
        win.destroy();
        resolve();
      });
    });

    if (!win.loadURL(`${learnCo}/ide/token?ide_config=true`)) {
      atom.notifications.warning('Learn IDE: connectivity issue', {
        detail: `The editor is unable to connect to ${learnCo}. Are you connected to the internet?`,
        buttons: [
          {text: 'Try again', onDidClick() { learnSignIn(); }}
        ]
      });
    }})
};

function learnSignIn() {
  return new Promise((resolve, reject) => {
    var win = new BrowserWindow({autoHideMenuBar: true, show: false, width: 400, height: 600, resizable: false});
    var {webContents} = win;

    win.setSkipTaskbar(true);
    win.setMenuBarVisibility(false);
    win.setTitle('Welcome to the Learn IDE');

    webContents.on('did-finish-load', () => win.show());

    webContents.on('new-window', (e, url) => {
      e.preventDefault();
      win.destroy();
      shell.openExternal(url);
    });

    webContents.on('will-navigate', (e, url) => {
      if (url.match(/github_sign_in/)) {
        win.destroy();
        githubLogin().then(resolve);
      }
    });

    webContents.on('did-get-redirect-request', (e, oldURL, newURL) => {
      if (newURL.match(/ide_token/)) {
        var token = _url.parse(newURL, true).query.ide_token;

        if (token != null && token.length) {
          confirmOauthToken(token).then((res) => {
            if (!res) { return; }
            _token.set(token);
            resolve();
          });
        }
      }

      if (newURL.match(/github_sign_in/)) {
        win.destroy();
        githubLogin().then(resolve);
      }
    });

    if (!win.loadURL(`${learnCo}/ide/sign_in?ide_onboard=true`)) {
      win.destroy();
      githubLogin.then(resolve);
    }
  })
}

export default function() {
  var existingToken = _token.get();
  return (!existingToken) ? learnSignIn() : confirmOauthToken(existingToken)
}

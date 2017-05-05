'use babel'

import localStorage from './local-storage'
import fetch from './fetch'
import {learnCo} from './config'
import {shell} from 'electron'

const key = 'learn-ide:remote-notification-id'

function checkForRemoteNotification() {
  var url = `${learnCo}/api/v1/learn_ide/notification`
  fetch(url).then(handleRemoteNotification)
}

function handleRemoteNotification(remoteNotification) {
  var recentId = parseInt(localStorage.get(key));
  if (recentId === remoteNotification.id) { return }

  if (!remoteNotification.active) { return }

  var expiration = Date.parse(remoteNotification.expires)
  if (Date.now() > expiration) { return }

  localStorage.set(key, remoteNotification.id)
  createNotification(remoteNotification.notification)
}

function createNotification(notification) {
  var {description, detail, dismissable, icon, buttons} = notification.options;

  buttons = buttons.map((button) => {
    if (button.onDidClick != null) {
      var url = button.onDidClick;
      button.onDidClick = () => shell.openExternal(url)
    }
    return button
  })

  atom.notifications.addInfo(notification.message, {
    description,
    detail,
    dismissable,
    icon,
    buttons
  });
}

export default function remoteNotification() {
  checkForRemoteNotification();

  var oneMinute = 60000;
  setInterval(checkForRemoteNotification, oneMinute * 20);
}

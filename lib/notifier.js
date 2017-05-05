'use babel'

import AtomSocket from 'atom-socket'
import atomHelper from './atom-helper'
import fetch from './fetch'
import querystring from 'querystring'
import {learnCo} from './config'

import submission from './notifications/submission'

var notificationStrategies = {submission}

export default class Notifier {
  constructor(token) {
    this.token = token;
  }

  activate() {
    return this.authenticate().then(({id}) => {
      this.connect(id);
    });
  }

  authenticate() {
    var headers = new Headers({'Authorization': `Bearer ${this.token}`});
    return fetch(`${learnCo}/api/v1/users/me`, {headers})
  }

  connect(userID) {
    this.ws = new AtomSocket('notif', `wss://push.flatironschool.com:9443/ws/fis-user-${userID}`)

    this.ws.on('message', msg => this.parseMessage(JSON.parse(msg)))
  }

  parseMessage({text}) {
    if (atomHelper.isLastFocusedWindow()) {
      var data = querystring.parse(text);

      var strategy = notificationStrategies[data.type];
      var strategyIsDefined = typeof strategy === 'function';

      return strategyIsDefined ? strategy(data) : undefined
    }
  }

  deactivate() {
    this.ws.close();
  }
}

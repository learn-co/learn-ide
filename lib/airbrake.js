'use babel'

import commandLog from './command-log'
import {learnCo} from './config'
import post from './post'
import token from './token'
import version from './version'

function defaultData() {
  return {
    commands: commandLog.get(),
    location: undefined,
    message: undefined,
    occurred_at: new Date(),
    platform: process.platform,
    stake: undefined,
    token: token.get(),
    version: version
  };
}

export default {
  notify(data={}) {
    var payload = Object.assign({}, defaultData(), data);

    var url = `${learnCo}/api/v1/learn_ide_airbrake`;

    return post(url, {payload}, {'Authorization': `Bearer ${payload.token}`});
  }
}


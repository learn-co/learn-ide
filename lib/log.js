'use babel'

import commandLog from './command-log'
import {learnCo} from './config'
import {post, patch} from './http'
import token from './token'
import version from './version'

function defaultData() {
  return {
    code: undefined,
    commands: commandLog.get(),
    event: undefined,
    host_ip: window.LEARN_IDE_HOST_IP,
    location: undefined,
    message: undefined,
    occurred_at: new Date(),
    platform: process.platform,
    reason: undefined,
    token: token.get(),
    version: version
  };
},

export default {
  add(data={}) {
    var log = Object.assign({}, defaultData(), data);

    var createUrl = `${learnCo}/api/v1/learn_ide_logs`;

    return post(createUrl, JSON.stringify({log}), true);
  },

  update(id, data={}) {
    var log = Object.assign({}, data, {id});

    var updateUrl = `${learnCo}/api/v1/learn_ide_logs/${id}`;

    return patch(updateUrl, JSON.stringify({log}), true);
  }
}


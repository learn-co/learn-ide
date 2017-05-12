'use babel'

import AtomSocket from 'atom-socket'
import {EventEmitter} from 'events'

export default class Terminal {
  constructor(args={}) {
    this.emitter = new EventEmitter();

    this.host = args.host;
    this.port = args.port;
    this.path = args.path;
    this.token = args.token;

    this.hasFailed = false;

    this.connect();
  }

  connect(token) {
    this.socket = new AtomSocket('term', this.url());

    this.waitForSocket = new Promise(((resolve, reject) => {
      this.socket.on('open', e => {
        this.emit('open', e)
        resolve()
      })

      this.socket.on('open:cached', e => {
        this.emit('open', e)
        resolve()
      })

      this.socket.on('message', (msg='') => {
        var decoded = new Buffer(msg, 'base64').toString();
        this.emit('message', decoded)
      })

      this.socket.on('close', e => this.emit('close', e))

      this.socket.on('error', e => this.emit('error', e))
    }));

    return this.waitForSocket
  }

  emit() {
    return this.emitter.emit.apply(this.emitter, arguments);
  }

  on() {
    return this.emitter.on.apply(this.emitter, arguments);
  }

  url() {
    var {version} = require('../package.json');
    var protocol = (this.port === 443) ? 'wss' : 'ws';

    return `${protocol}://${this.host}:${this.port}/${this.path}?token=${this.token}&version=${version}`;
  }

  reset() {
    return this.socket.reset();
  }

  send(msg) {
    if (this.waitForSocket === null ) {
      this.socket.send(msg)
      return
    }

    this.waitForSocket.then(() => {
      this.waitForSocket = null;
      this.socket.send(msg);
    });
  }

  toggleDebugger() {
    this.socket.toggleDebugger();
  }

  debugInfo() {
    return {
      host: this.host,
      port: this.port,
      path: this.path,
      token: this.token,
      socket: this.socket
    };
  }
}

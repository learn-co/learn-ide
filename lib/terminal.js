'use babel'

import AtomSocket from 'atom-socket'
import { EventEmitter } from 'events'
import { Socket } from 'phoenix'

export default class Terminal {
  constructor(args={}) {
    this.emitter = new EventEmitter();

    this.host = args.host;
    this.port = args.port;
    this.path = args.path;
    this.token = args.token;
    this.username = args.username;

    this.hasFailed = false;

    this.connect();
  }

  connect() {
    this.socket = new Socket(this.url(), {params: {token: this.token}})
    this.socket.connect()

    this.channel = this.socket.channel(`session:${this.username}`)

    this.channel.join()
      .receive('error', (e) => { console.log('error connecting to session', e) })
      .receive('ok', (e) => {
        atom.emitter.emit('learn-ide:did-join-channel', this.channel)
        this.emit('open', e)
      })

    this.channel.on('terminal_output', ({terminal_output}) => {
      var decoded = new Buffer(terminal_output, 'base64').toString()
      this.emit('message', decoded)
    })

    this.channel.onClose(e => this.emit('close', e))
    this.channel.onError(e => this.emit('error', e))
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

    return `${protocol}://${this.host}:${this.port}/${this.path}`;
  }

  reset() {
    return this.socket.reset();
  }

  send(msg) {
    var encoded = new Buffer(msg).toString('base64')
    this.channel.push('terminal_input', {data: encoded})
  }
}

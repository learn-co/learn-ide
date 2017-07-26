'use babel'

import { EventEmitter } from 'events'
import { Socket } from 'phoenix'
import { name } from '../package.json'

export default class Terminal {
  constructor(args={}) {
    this.emitter = new EventEmitter();

    this.host = args.host;
    this.port = args.port;
    this.path = args.path;
    this.token = args.token;
    this.username = args.username;
    this.labSlug = args.labSlug;

    this.subscribe()
    this.connect();
  }

  subscribe() {
    this.on('open', () => atom.emitter.emit('learn-ide:connection-open', this.channel))
    this.on('error', () => atom.emitter.emit('learn-ide:connection-error'))
  }

  connect() {
    if (this.socket) { this.socket.disconnect() }

    this.socket = new Socket(this.url(), {params: {token: this.token, client: 'atom'}})
    this.socket.onError(() => this.emit('error'))
    this.socket.connect()

    this.channel = this.socket.channel(this.channelName())

    this.channel.on('terminal_output', ({terminal_output}) => {
      var decoded = new Buffer(terminal_output, 'base64').toString()
      this.emit('message', decoded)
    })

    this.channel.onClose(() => this.emit('close'))

    this.channel.onError(() => {
      this.channel.leave()
      this.socket.reconnectTimer.callback = () => { } // noops to prevent auto reconnects
      this.socket.disconnect()
      this.emit('error')
    })

    this.channel.join()
      .receive('error', () => this.emit('error'))
      .receive('ok', () => this.emit('open'))
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

  channelName() {
    let defaultOpen = atom.config.get(`${name}.openOnHome`) ? 'home' : 'temporary'

    return `session:${this.username}:${this.labSlug || defaultOpen}`
  }

  reset() {
    return this.connect()
  }

  send(msg) {
    var encoded = new Buffer(msg).toString('base64')
    this.channel.push('terminal_input', {data: encoded})
  }
}

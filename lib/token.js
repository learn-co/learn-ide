'use babel'

import localStorage from './local-storage'
import bus from './event-bus'

var tokenKey = 'learn-ide:token';

export default {
  get() {
    return localStorage.get(tokenKey);
  },

  set(value) {
    localStorage.set(tokenKey, value);
    bus.emit(tokenKey, value);
  },

  unset() {
    localStorage.delete(tokenKey);
    bus.emit(tokenKey, undefined);
  },

  observe(callback) {
    callback(this.get());
    bus.on(tokenKey, callback);
  }
}

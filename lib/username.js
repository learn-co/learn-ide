'use babel'

import localStorage from './local-storage'

var tokenKey = 'learn-ide:username';

export default {
  get() {
    return localStorage.get(tokenKey);
  },

  set(value) {
    localStorage.set(tokenKey, value);
  },

  unset() {
    localStorage.delete(tokenKey);
  }
}

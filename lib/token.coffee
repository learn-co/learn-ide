localStorage = require './local-storage'
bus = require('./event-bus')()

TOKEN_KEY = 'learn-ide:token'

module.exports = token = {
  get: ->
    localStorage.get(TOKEN_KEY)

  set: (value) ->
    localStorage.set(TOKEN_KEY, value)
    bus.emit(TOKEN_KEY, value)

  unset: ->
    localStorage.delete(TOKEN_KEY)
    bus.emit(TOKEN_KEY, undefined)

  observe: (callback) ->
    callback(token.get())
    bus.on(TOKEN_KEY, callback)
}

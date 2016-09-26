localStorage = require './local-storage'

module.exports =
  isLastFocusedWindow: ->
    parseInt(localStorage.get('lastFocusedWindow')) == process.pid

  setLastFocusedWindow: ->
    localStorage.set('lastFocusedWindow', process.pid)

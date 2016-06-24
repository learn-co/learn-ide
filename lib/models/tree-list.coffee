fs = require 'fs-plus'

module.exports =
class TreeList
  constructor: (@path) ->
    @_loadEntries()

  reload: ->
    @_loadEntries()

  has: (path) ->
    @entries.indexOf(path) isnt -1

  _loadEntries: ->
    @entries = fs.listTreeSync(@path)

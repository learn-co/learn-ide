fs = require 'fs-plus'

module.exports =
class FileSystemTree
  constructor: (@path) ->
    @_loadEntries()

  reload: ->
    @_loadEntries()

  isFile: (path) ->
    fs.isFileSync(path)

  isDirectory: (path) ->
    fs.isDirectorySync(path)

  _loadEntries: ->
    @entries = fs.listTreeSync(@path)

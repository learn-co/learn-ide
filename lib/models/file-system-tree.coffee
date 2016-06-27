fs = require 'fs-plus'

module.exports =
class FileSystemTree
  constructor: (@path) ->
    @entries = @loadEntries()

  reload: ->
    @entries = @loadEntries()

  isFile: (path) ->
    fs.isFileSync(path)

  isDirectory: (path) ->
    fs.isDirectorySync(path)

  loadEntries: ->
    fs.listTreeSync(@path)

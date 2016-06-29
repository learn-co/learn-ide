fs = require 'fs-plus'

module.exports =
class FileSystemTree
  constructor: (@path) ->
    @entries = fs.listTreeSync(@path)

  reload: ->
    @entries = fs.listTreeSync(@path)

  isFile: (path) ->
    fs.isFileSync(path)

  isDirectory: (path) ->
    fs.isDirectorySync(path)

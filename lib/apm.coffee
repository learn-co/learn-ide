{BufferedProcess} = require 'atom'

run = (args) ->
  new Promise (resolve) ->
    command = atom.packages.getApmPath()

    log = ''

    stdout = (data) ->
      log += "#{data}"

    stderr = (data) ->
      log += "#{data}"

    exit = (code) ->
      resolve({log, code})

    new BufferedProcess({command, args, stdout, stderr, exit})

fullname = (name, version) ->
  if version? then "#{name}@#{version}" else name

parseNameAndVersionObject = (namesAndVersions) ->
  fullnames = []

  for name, version of namesAndVersions
    fullnames.push(fullname(name, version))

  fullnames

module.exports = apm =
  install: (name, version) ->
    args =
      if typeof name is 'object'
        parseNameAndVersionObject(name)
      else
        [fullname(name, version)]

    run(['install', '--compatible', '--no-confirm', '--no-color'].concat(args))



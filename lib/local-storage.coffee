module.exports =
  get: (key) ->
    localStorage[key]
  set: (key, value) ->
    localStorage[key] = value

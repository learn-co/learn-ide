module.exports =
  get: (key) ->
    localStorage[key]
  set: (key, value) ->
    localStorage[key] = value
  delete: (key) ->
    delete localStorage[key]

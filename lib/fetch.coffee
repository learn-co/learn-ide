module.exports = fetchWrapper = (url, init) ->
  fetch(url, init)
    .then (response) -> response.text()
    .then (body) -> JSON.parse(body)


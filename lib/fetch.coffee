module.exports = fetchWrapper = (url) ->
  fetch(url)
    .then (response) -> response.text()
    .then (body) -> JSON.parse(body)


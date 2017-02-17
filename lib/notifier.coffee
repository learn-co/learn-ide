querystring = require 'querystring'
AtomSocket = require 'atom-socket'
atomHelper = require './atom-helper'
fetch = require './fetch'
{learnCo} = require './config'

notificationStrategies =
  submission: require('./notifications/submission')

module.exports =
class Notifier
  constructor: (token) ->
    @token = token

  activate: ->
    @authenticate().then ({id}) =>
      @connect(id)

  authenticate: ->
    headers = new Headers({'Authorization': "Bearer #{@token}"})
    fetch("#{learnCo}/api/v1/users/me", {headers})

  connect: (userID) ->
    @ws = new AtomSocket('notif', "wss://push.flatironschool.com:9443/ws/fis-user-#{userID}")

    @ws.on 'message', (msg) =>
      @parseMessage(JSON.parse(msg))

  parseMessage: ({text}) ->
    if atomHelper.isLastFocusedWindow()
      data = querystring.parse(text)
      callback = notificationStrategies[data.type]
      callback?(data)

  deactivate: ->
    @ws.close()


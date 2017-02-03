path = require 'path'
fetch = require '../fetch'
{learnCo} = require '../config'
submissionRegistry = []
cachedLessonTitles = {}

getLessonTitle = (lessonID) ->
  title = cachedLessonTitles[lessonID]

  if title?
    return Promise.resolve(title)

  fetch("#{learnCo}/api/v1/lessons/#{lessonID}").then ({title}) =>
    cachedLessonTitles[lessonID] = title || 'Learn IDE'
    return title

icon = (passing) ->
  pass = path.resolve(__dirname, '..', '..', 'static', 'images', 'pass.png')
  fail = path.resolve(__dirname, '..', '..', 'static', 'images', 'fail.png')
  if passing is 'true' then pass else fail

module.exports = ({submission_id, lesson_id, passing, message}) ->
  if not submissionRegistry.includes(submission_id)
    submissionRegistry.push(submission_id)

    getLessonTitle(lesson_id).then (title) =>
        notif = new Notification(title, {body: message, icon: icon(passing)})
        notif.onclick = -> notif.close()


'use babel'

import path from 'path'
import fetch from '../fetch'
import {learnCo} from '../config'

var submissionRegistry = [];
var cachedLessonTitles = {};

function getLessonTitle(lessonID) {
  var title = cachedLessonTitles[lessonID];

  if (title != null) { return Promise.resolve(title) }

  return fetch(`${learnCo}/api/v1/lessons/${lessonID}`).then(({title}) => {
    cachedLessonTitles[lessonID] = title || 'Learn IDE';
    return title;
  });
};

function icon(passing) {
  var pass = path.resolve(__dirname, '..', '..', 'static', 'images', 'pass.png');
  var fail = path.resolve(__dirname, '..', '..', 'static', 'images', 'fail.png');

  return (passing === 'true') ? pass : fail
};

export default function({submission_id, lesson_id, passing, message}) {
  if (submissionRegistry.includes(submission_id)) { return }

  submissionRegistry.push(submission_id);

  getLessonTitle(lesson_id).then((title) => {
    var notif = new Notification(title, {body: message, icon: icon(passing)});
    notif.onclick = () => notif.close();
  });
}


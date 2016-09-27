var shell = require('electron').shell

var updateCheck = JSON.parse(localStorage.getItem('updateCheck'))
var downloadURL = updateCheck.downloadURL
var outOfDate = updateCheck.outOfDate

if (outOfDate) {
  document.getElementById('download-link').href = downloadURL
  document.getElementById('out-of-date').classList.remove('hidden')
} else {
  document.getElementById('up-to-date').classList.remove('hidden')
}

function openExternal (e) {
  e.preventDefault()
  shell.openExternal(e.currentTarget.href)
}

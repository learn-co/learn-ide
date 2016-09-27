var shell = require('electron').shell

function openExternal (e) {
  alert('hello world')
  e.preventDefault()
  shell.openExternal(e.currentTarget.href)
}

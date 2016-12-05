protocol = require 'register-protocol-win32'

protocol.install('learn-ide', "#{process.execPath} \"%1\"")
	.then ->
		console.log 'success'
  .catch (err) ->
		console.error(err)

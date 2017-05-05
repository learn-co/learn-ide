'use babel'

import protocol from 'register-protocol-win32'

protocol.install('learn-ide', `${process.execPath} --url-to-open=\"%1\"`)

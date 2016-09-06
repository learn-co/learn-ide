1. Object organization
  - remove global fs in favor of something learn-ide
  - fs = require 'learn-store'.fs
  - IDEStore
    - @fs
    - @websocket
    - @entries
  - store-node
    - @stat shit
  - fsAdapter
    - @store
2. Background Sync

3. Save events

4. Project search & replace

class VirtualFileSystem
  constructor:

class VirtualFile

class VirtualFS
  constructor:
    @

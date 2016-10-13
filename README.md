# Learn IDE

[Learn IDE](https://learn.co/ide) is a fully featured text editor for [Learn](https://learn.co). It provides a remote development environment to allow users to get started coding using real tools without the pain of setting one up locally. It is built on top of Github's open source [Atom editor](https://atom.io/).

## Project Structure

The Learn IDE client is a modified Atom build with two packages injected to provide functionality with a remote backend that provides a ready to go development environment for [Learn](https://learn.co) users.

**Atom Packages:**

- **[Learn IDE](https://github.com/flatiron-labs/integrated-learn-environment)** - The main extension
- **[Tree View](https://github.com/learn-co/learn-ide-tree)** - Our fork of Atom's [tree view](https://github.com/atom/tree-view). Intercepts Atom's file system events and instead performs them on our remote backend.

**Related libraries:**

Those two packages include a couple important libraries:

- **[nsync-fs](https://github.com/learn-co/nsync-fs)** A virtual file system for keeping Atom synced with the remote server
- **[single-socket](https://github.com/learn-co/single-socket)** A library for sharing a single websocket connection across multiple Node processes. Every Atom window is a separate process and we want to share our server connection between all of them.

## Getting Started

1. Build our [fork of Atom](https://github.com/flatiron-labs/atom-ile)
2. `apm link` - This will create a sym link to your .atom directory, making the plugin available for use.
3. `npm install`
4. `npm install gulp-cli -g` - Gulp is our task runner, install this to use the global CLI command
5. `gulp clone` - *optional* - This will clone down all related Learn IDE repos. They will be cloned to this repos parent directory (`..`)
6. `gulp setup`
6. `gulp` - This will connect to our dev websocketd server (hosting the terminal and fs server) start up the daemon on the port specified in `.env` (should be added after running `gulp setup` above)
7. Open the Learn IDE

## Gulp Tasks

- `gulp` - Default task of `gulp ws:start`
- `gulp setup` - Set up project. Copies over `.env.example` to `.env`.
- `gulp build` - Builds the Atom application with our packages injected ready for distribution.
- `gulp ws:start` - Starts up the remote WebSocketd daemon on `vm02.students.learn.co` (both the terminal and fs server). The websocket logs will be piped back to your terminal. On exit, the websocketd processes will be cleaned up and killed on the server.

# Learn IDE

[Learn IDE](https://learn.co/ide) is a fully featured text editor for [Learn](https://learn.co). It provides a remote development environment to allow users to get started coding using real tools without the pain of setting one up locally. It is built on top of Github's open source [Atom editor](https://atom.io/).

## Project Structure

This project is composed of multiple repositories, which can be divided into two areas of responsibility the **front end** and the **back end**:

### Front End

- **[Integrated Learn Environment](https://github.com/flatiron-labs/integrated-learn-environment)** - This repo, currently holds the main entry to the project and various modules and resources used in our Atom fork.
- **[Atom ILE](https://github.com/flatiron-labs/atom-ile)** - Our fork of Atom.
- **[Tree View](https://github.com/learn-co/tree-view/)** - Our fork of Atom's [tree view](https://github.com/atom/tree-view).
- **[Learn IDE Windows Packager](https://github.com/flatiron-labs/learn-ide-windows-packager)** - Scripts for packaging releases for Windows
- **[Learn IDE Mac Packager](https://github.com/flatiron-labs/learn-ide-mac-packager)** - Scripts for packaging releases for Mac

### Back End

- **[FS Server](https://github.com/flatiron-labs/fs_server)** - Syncs the local file system with our remote host through a websocket. Written in Ruby.
- **[Go Terminal Server](https://github.com/flatiron-labs/go_terminal_server)** - Runs terminal commands from the client and returns the output to the client through a websocket. Written in Go.
- **[Students Chef Repo](https://github.com/flatiron-labs/students-chef-repo)** - Chef server that automates student Unix account creation on our back end VMs.

### Gulp Tasks

- `gulp` - Default task of `gulp ws:start`
- `gulp ws:start` - Starts up the remote WebSocketd daemon on `vm02.students.learn.co` (both the terminal and fs server). The websocket logs will be piped back to your terminal. On exit, the websocketd processes will be cleaned up and killed on the server.
- `gulp clone` - Clones down all related Learn IDE into this repo's parent directory.

## Getting Started

1. Build our [fork of Atom](https://github.com/flatiron-labs/atom-ile) 2. `apm link` - This will create a sym link to your .atom directory, making the plugin available for use.
3. `npm install`
4. `npm install gulp-cli -g` - Gulp is our task runner, install this to use the global CLI command
5. `gulp clone` - *optional* - This will clone down all related Learn IDE repos. They will be cloned to this repos parent directory (`..`)
6. Start fs and terminal server on `vm02.students.learn.co` and update local code (development sandbox)
  - `ssh vm02.students.learn.co`
  - `sudo su - deployer`
  - `websocketd --port=4463 --dir=/home/deployer/websocketd_scripts`
  - Update your socket connections in [lib/integrated-learn-environment.coffee](lib/integrated-learn-environment.coffee)
7. Open the Learn IDE

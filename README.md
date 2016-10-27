# Learn IDE

[Learn IDE](https://learn.co/ide) is a fully featured text editor for [Learn](https://learn.co). It provides a remote development environment to allow users to get started coding using real tools without the pain of setting one up locally. It is built on top of Github's open source [Atom editor](https://atom.io/).

## Project Structure

The Learn IDE client is a modified Atom build with two packages injected to provide functionality with a remote backend that provides a ready to go development environment for [Learn](https://learn.co) users.

**Atom Packages:**

- **[Learn IDE](https://github.com/flatiron-labs/integrated-learn-environment)** - The main extension
- **[Learn IDE Tree](https://github.com/learn-co/learn-ide-tree)** - Our fork of Atom's [tree view](https://github.com/atom/tree-view). Intercepts Atom's file system events and instead performs them on our remote backend.

**Related libraries:**

Those two packages include a couple important libraries:

- **[nsync-fs](https://github.com/learn-co/nsync-fs)** A virtual file system for keeping Atom synced with the remote server
- **[single-socket](https://github.com/learn-co/single-socket)** A library for sharing a single websocket connection across multiple Node processes. Every Atom window is a separate process and we want to share our server connection between all of them.

## Getting Started

1. Download [Atom](https://atom.io/)
2. Clone this repo and [learn-ide-tree](https://github.com/learn-co/learn-ide-tree)
3. Run `npm install` in both repos
4. Run `apm link` inside both repos - This will create a sym link to your .atom directory, making the plugin available for use.
5. Open Atom

## Building the Learn IDE

`gulp build` - Builds the Atom application with our packages injected ready for distribution and swaps out icons and names to brand it the Learn IDE.

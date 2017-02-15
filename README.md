# Learn IDE

[Learn IDE](https://learn.co/ide) is a fully featured text editor for [Learn](https://learn.co). It provides a remote development environment to allow users to get started coding using real tools without the pain of setting one up locally. It is built on top of Github's open source [Atom editor](https://atom.io/).

## Project Structure

The Learn IDE client is a modified Atom build with two packages injected to provide functionality with a remote backend that provides a ready to go development environment for [Learn](https://learn.co) users.

**Atom Packages:**

- **[Learn IDE](https://github.com/learn-co/learn-ide)** - The main extension
- **[Learn IDE Tree](https://github.com/learn-co/learn-ide-tree)** - Our fork of Atom's [tree view](https://github.com/atom/tree-view). Intercepts Atom's file system events and instead performs them on our remote backend.

**Related libraries:**

Those two packages include a couple important libraries:

- **[nsync-fs](https://github.com/learn-co/nsync-fs)** A virtual file system for keeping Atom synced with the remote server
- **[atom-socket](https://github.com/learn-co/atom-socket)** A library for sharing a single websocket connection in Atom packages.

## Getting Started

1. Download [Atom](https://atom.io/)
2. Clone this repo and [learn-ide-tree](https://github.com/learn-co/learn-ide-tree)
3. Run `npm install` in both repos
4. Run `apm link` inside both repos - This will create a sym link to your .atom directory, making the plugin available for use.
5. Open Atom

## Building the Learn IDE

`gulp build` - Builds the Atom application with our packages injected ready for distribution and swaps out icons and names to brand it the Learn IDE. On Mac, this will automatically attempt to sign the application. On Windows, the installer must be signed manually.

## Releasing

Publish: `apm publish <major|minor|version>` - bumps version in `package.json`, tags it, and publishes the tag to apm
Build: see above
Release: convert the tag to a release on Github, and attach the binaries for each platform to the release

### Beta Release
1. Give the package a beta version in the `package.json`, e.g. the pre-release version for v2.5.0 would be `2.5.0-beta0`
2. Commit that version change, and tag it as `v<version>`, e.g. `git commit -am "prep v2.5.0-beta0" && git tag v2.5.0-beta0`
3. Push the commit and the tag: `git push && git push --tags`
4. Publish the new tag on apm: `apm publish --tag <tag>`, e.g. `apm publish --tag v2.5.0-beta0`
5. Build & release as described above, but be sure to check the box indicating that this is a pre-release when editing the tag on Github

## Atom and Electron

The Learn IDE application currently uses [Atom at v1.13.0](https://github.com/atom/atom/tree/v1.13.0/docs), which runs [Electron at v1.3.13](https://github.com/electron/electron/tree/v1.3.13/docs). While developling, be sure that you are referring to the documentation that corresponds to these specific versions.

## License

Learn IDE is [MIT licensed](LICENSE.md)

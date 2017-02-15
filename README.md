# Learn IDE

[Learn IDE](https://learn.co/ide) is a fully featured text editor for [Learn](https://learn.co). It provides a remote development environment to allow users to get started coding using real tools without the pain of setting one up locally. It is built on top of Github's open source [Atom editor](https://atom.io/).

## Project Structure

The Learn IDE client is a modified Atom build with two packages injected to provide functionality with a remote backend that provides a ready to go development environment for [Learn](https://learn.co) users.

**Atom Packages:**

- **[Learn IDE](https://github.com/learn-co/learn-ide)** - The main extension
- **[Learn IDE Tree](https://github.com/learn-co/learn-ide-tree)** - Our fork of Atom's [tree view](https://github.com/atom/tree-view). Intercepts Atom's file system events and instead performs them on our remote backend.
- **[Learn IDE Material UI](https://github.com/learn-co/learn-ide-material-ui)** - Our fork of [atom-material-ui](https://github.com/atom-material/atom-material-ui) with our own set of default configurations

**Related libraries:**

Those two packages include a couple important libraries:

- **[nsync-fs](https://github.com/learn-co/nsync-fs)** A virtual file system for keeping Atom synced with the remote server
- **[atom-socket](https://github.com/learn-co/atom-socket)** A library for sharing a single websocket connection in Atom packages.

## Atom and Electron

The Learn IDE application currently uses [Atom at v1.14.2](https://github.com/atom/atom/tree/v1.14.2/docs), which runs [Electron at v1.3.13](https://github.com/electron/electron/tree/v1.3.13/docs). While developling, be sure that you are referring to the documentation that corresponds to these specific versions.

## Getting Started

1. Download [Atom](https://atom.io/)
2. Clone the package repos:
```shell
git clone https://github.com/learn-co/learn-ide.git
git clone https://github.com/learn-co/learn-ide-tree.git
git clone https://github.com/learn-co/learn-ide-material-ui.git
```
3. Run `npm install` in each repo
4. Run `apm link` inside each repo - This will create a sym link to your .atom directory, making the plugin available for use.
5. Open Atom

## Building the Learn IDE

`gulp build` - Builds the Atom application with our packages injected ready for distribution and swaps out icons and names to brand it the Learn IDE. On Mac, this will automatically attempt to sign the application using Flatiron School's development certificate (which must be installed on your machine). On Windows, the installer must be signed manually.

## Releasing

Ensure the `packageDependencies` are up-to-date in `package.json`, then:

1. **Publish**: `apm publish <major|minor|patch>` - bumps the package version according to the specified semver segment, tags it, and publishes the tag to apm
2. **Build**: see [building](#building-the-learn-ide)
3. **Release**: convert the tag to a release on Github, and attach the binaries you've built for each platform to the release

### Beta Release
1. Give the package a beta version in the `package.json`, e.g. the pre-release version for v2.5.0 would be `2.5.0-beta0`
2. Commit that version change, and tag it as `v<version>`, e.g. `git commit -am "prep v2.5.0-beta0" && git tag v2.5.0-beta0`
3. Push the commit and the tag: `git push && git push --tags`
4. Publish the new tag on apm: `apm publish --tag <tag>`, e.g. `apm publish --tag v2.5.0-beta0`
5. Build & release as described above, but be sure to check the box indicating that this is a pre-release when creating the release on Github

## dotenv

You can configure the Learn IDE by creating a `.env` file either in Atom's home (e.g. `~/.atom/.env`) or wherever the package is being run (e.g. `~/development-stuff/learn-ide/.env`). The following keys can be used:

Key              | Default Value      | Function
---------------- | ------------------ | --------
IDE_WS_HOST      | `ile.learn.co`     | The host used for websocket connections
IDE_WS_PORT      | `443`              | The port used for websocket connections
IDE_WS_TERM_PATH | `v2/terminal`      | The path used for websocket connections
IDE_LEARN_CO     | `https://learn.co` | The location of learn to connect to

The `IDE_LEARN_CO` key is useful for developers and testers at Flatiron School, as it can be used to point the client to a local or QA environment; however, it does not change the IDE server's knowledge of Learn's location. In other words, you must sign in to the IDE with a production user, as the IDE servers will authenticate you against the Learn production environment.

## License

Learn IDE is [MIT licensed](LICENSE.md)

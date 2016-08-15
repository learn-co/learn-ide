# Learn IDE

[Learn IDE](https://learn.co/ide) is a fully featured text editor for [Learn](https://learn.co). It provides a remote development environment to allow users to get started coding using real tools without the pain of setting up a local development environment. It is built on top of Github's open source [Atom editor](https://atom.io/).

## Project Structure

The project is composed of multiple repositories, which can be divided into two areas of responsibility the **front end** and the **back end**:

### Front End

- **[Atom ILE](https://github.com/flatiron-labs/atom-ile)**
- **[Tree View](https://github.com/learn-co/tree-view/)**
- **[Learn IDE Windows Packager](https://github.com/flatiron-labs/learn-ide-windows-packager)**
- **[Learn IDE Mac Packager](https://github.com/flatiron-labs/learn-ide-mac-packager)**

### Back End

- **[FS Server](https://github.com/flatiron-labs/fs_server)**
- **[Go Terminal Server](https://github.com/flatiron-labs/go_terminal_server)**
- **[Students Chef Repo](https://github.com/flatiron-labs/students-chef-repo)**

## Design Principles

<img align="right" src="diagram.png" />

The goal of this package is to provide Atom with an integration to Learn that is as OS-independent as possible. To meet this goal, the Atom API should be relied upon wherever possible. The point of this is to provide a reasonable level of confidence that wherever Atom can run, the Learn Integrated Environment can also run.

To accomplish this, some design principles are presented:

* Terminal interaction should be "dumb".
  * Assume the host doesn't have a native SSH client, as is the case with Windows.
  * Assume the host doesn't have support for a scripting language, as is the case with Windows (PowerShell may or may not exist, depending on the version of Windows).
  * Forward input to the student's server.
* Reliance on a filesystem structure should be minimal. Don't assume certain paths exist.

# Setup

1. Clone this repository and run `apm link`. This will create a sym link to your .atom directory, making the plugin available for use.
2. `bundle install` and `npm install`
3. Start atom with `atom -d`.
4. Right click in a text buffer and select the "Toggle Learn.co Terminal" option.

# NOTES

1. To start websocketd correctly: `websocketd --port=4463 --ssl --sslcert=ile.learn.co.crt --sslkey=ile.learn.co.key --address=ile.learn.co ./terminal_server`

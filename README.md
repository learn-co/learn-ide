# Integrated Learn Environment Package

The goal of this package is to provide Atom with an integration to Learn that is asOS-independent as possible. To meet this goal, Atom scripting should be relied upon wherever possible. The point of this is to provide a reasonable level of confidence that wherever Atom can run, the Learn Integrated Environment can also run.

To accomplish this, some design principles are presented:

* Console I/O should be handled directly by a SSH JS library (i.e. tty.js).
  * Assume the host doesn't have a native SSH client, as is the case with Windows.
  * Assume the host doesn't have support for a scripting language, as is the case with Windows (PowerShell may or may not exist, depending on the version of Windows).
* Reliance on a filesystem structure should be minimal. Don't assume certain paths exist.

![A screenshot of your package](https://f.cloud.github.com/assets/69169/2290250/c35d867a-a017-11e3-86be-cd7c5bf3ff9b.gif)

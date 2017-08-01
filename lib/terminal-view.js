'use babel'

import TerminalEmulator from 'xterm';
import path from 'path';
import { $, View } from 'atom-space-pen-views';
import { BrowserWindow } from 'remote';
import { clipboard } from 'electron';

import bus from './event-bus';
import colors from './colors';
import localStorage from './local-storage';
import { name } from '../package.json';
import fs from 'fs'
import { app } from 'remote'

TerminalEmulator.loadAddon('fit');

const popoutEmulatorFile = path.resolve(__dirname, 'popout-emulator.html');

const heightKey = 'learn-ide:currentTerminalHeight'

const verticalLimit = 100;
const defaultHeight = 275;

class TerminalView extends View {
  static content() {
    return this.div({class: 'terminal-resizer tool-panel'}, () => {
      this.div({class: 'terminal-resize-handle', outlet: 'resizeHandle'});
    });
  }

  initialize(terminal) {
    this.terminal = terminal;
    this.emulator = new TerminalEmulator({cursorBlink: true, rows: 16});

    this.attach();
    this.subscribe();
    this.resizeAfterDrag = this.resizeAfterDrag.bind(this)
  }

  attach() {
    atom.workspace.addBottomPanel({item: this});
    this.emulator.open(this.element, true);
    this.restoreHeight()
  }

  subscribe() {
    this.emulator.attachCustomKeydownHandler((e) => {
      if (this.isAttemptToScroll(e) || this.isAttemptToSave(e)) {
        e.preventDefault()
        return false
      }
    })

    this.emulator.on('data', (data) => {
      this.sendToTerminal(data, event);
    });

    this.terminal.on('message', (msg) => {
      this.writeToEmulator(msg);
    });

    bus.on('popout-emulator:data', (data) => {
      this.sendToTerminal(data);
    });

    this.on('mousedown', '.terminal-resize-handle', (e) => {
      this.resizeByDragStarted(e);
    });

    this.on('mouseup', '.terminal-resize-handle', (e) => {
      this.resizeByDragStopped(e);
    });
  }

  sendToTerminal(data) {
    this.terminal.send(data)
  }

  writeToEmulator(text) {
    this.emulator.write(text);

    if (this.hasPopoutEmulator()) {
      bus.emit('popout-emulator:write', text);
    }
  }

  isAttemptToSave({keyCode, ctrlKey}) {
    // ctrl-s on windows and linux
    return ctrlKey && (keyCode === 83) && (process.platform !== 'darwin')
  }

  isAttemptToScroll({keyCode, ctrlKey, metaKey, altKey}) {
    var isUpOrDown = [38, 40].includes(keyCode);

    if (!isUpOrDown) { return false }

    // ctrl-up/down on windows and linux
    if (process.platform !== 'darwin') { return ctrlKey }

    // cmd-up/down or ctrl-alt-up/down on mac
    return metaKey || (ctrlKey && altKey)
  }

  loadPopoutEmulator() {
    return new Promise((resolve) => {
      localStorage.set('popout-emulator:css', colors.getCSS());
      localStorage.set('popout-emulator:font-size', this.currentFontSize())
      localStorage.set('popout-emulator:font-family', $(this.emulator.element).css('font-family'))

      let xterm = path.join(app.getAppPath(), 'node_modules', 'xterm', 'dist', 'xterm.css')
      let fullscreen = path.join(app.getAppPath(), 'node_modules', 'xterm', 'dist', 'addons', 'fullscreen', 'fullscreen.css')
      localStorage.set('popout-emulator:xterm-css', fs.readFileSync(xterm))
      localStorage.set('popout-emulator:fullscreen-css', fs.readFileSync(fullscreen))

      this.popout = new BrowserWindow({title: 'Learn IDE Terminal', show: false, autoHideMenuBar: true});
      this.popout.loadURL(`file://${popoutEmulatorFile}`);

      this.popout.once('ready-to-show', () => resolve(this.popout));
      this.popout.on('closed', () => this.show());
    });
  }

  hasPopoutEmulator() {
    return (this.popout != null) && !this.popout.isDestroyed();
  }

  focusPopoutEmulator() {
    if (this.hasPopoutEmulator()) {
      this.hide();
      this.popout.focus();
      return;
    }

    this.loadPopoutEmulator().then(() => {
      this.hide();
      this.popout.show();
    });
  }

  clipboardCopy() {
    var selection = document.getSelection();
    var rawText = selection.toString();
    var preparedText = rawText.replace(/\u00A0/g, ' ').replace(/\s+(\n)?$/gm, '$1');

    clipboard.writeText(preparedText);
  }

  clipboardPaste() {
    var rawText = clipboard.readText();
    var preparedText = rawText.replace(/\n/g, '\r');

    this.sendToTerminal(preparedText);
  }

  toggleFocus() {
    var hasFocus = document.activeElement === this.emulator.textarea;

    hasFocus ? this.transferFocus() : this.focusEmulator()
  }

  transferFocus() {
    atom.workspace.getActivePane().activate();
  }

  focusEmulator() {
    this.emulator.focus();
  }

  scrollUp() {
    this.emulator.scrollDisp(-1);
  }

  scrollDown() {
    this.emulator.scrollDisp(1);
  }

  setFontFamily(fontFamily) {
    var value = 'courier-new, courier, monospace';

    if (fontFamily.length) { value = `${fontFamily}, ${value}` }

    $(this.emulator.element).css('font-family', value)

    this.fit()
  }

  setFontSize(size) {
    this.css('font-size', size);
    this.fit()
  }

  currentFontSize() {
    return atom.config.get(`${name}.fontSize`);
  }

  increaseFontSize() {
    atom.config.set(`${name}.fontSize`, this.currentFontSize() + 2);
  }

  decreaseFontSize() {
    atom.config.set(`${name}.fontSize`, this.currentFontSize() - 2);
  }

  resetFontSize() {
    atom.config.unset(`${name}.fontSize`)
  }

  restoreHeight() {
    var height = localStorage.get(heightKey) || defaultHeight;
    this.setHeightWithFit(height)
  }

  setHeightWithFit(desiredHeight) {
    this.height(desiredHeight)
    this.fit()
  }

  resizeByDragStarted({target}) {
    $(document).on('mousemove', this.resizeAfterDrag)
  }

  resizeByDragStopped() {
    $(document).off('mousemove', this.resizeAfterDrag)
  }

  resizeAfterDrag({pageY, which}) {
    if (which !== 1) {
      this.resizeByDragStopped()
      return
    }

    var availableHeight = this.height() + this.offset().top;
    var proposedHeight  = availableHeight - pageY;

    var tooLarge = pageY < verticalLimit;
    var tooSmall = proposedHeight < verticalLimit;

    if (tooLarge) { proposedHeight = availableHeight - verticalLimit }
    if (tooSmall) { proposedHeight = verticalLimit }

    this.setHeightWithFit(proposedHeight)
  }

  fit() {
    // Two calls are necessary to properly fit after the font-size has changed
    this.emulator.fit()
    this.emulator.fit()

    var newHeight = this.getHeightForFit();

    this.height(newHeight)
    localStorage.set(heightKey, newHeight)
  }

  getHeightForFit() {
    var rowCount  = this.emulator.rows;
    var rowHeight = this.emulator.viewport.currentRowHeight;
    var emulatorHeight = rowCount * rowHeight;

    var paddingTop = parseInt(this.css('padding-top'));
    var paddingBottom = parseInt(this.css('padding-bottom'));
    var paddingHeight = paddingTop + paddingBottom;

    return emulatorHeight + paddingHeight
  }
}

export default TerminalView


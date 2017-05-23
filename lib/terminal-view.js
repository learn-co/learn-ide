'use babel'

import TerminalEmulator from 'xterm';
import path from 'path';
import { $, View } from 'atom-space-pen-views';
import { BrowserWindow } from 'remote';
import { clipboard } from 'electron';

import bus from './event-bus';
import colors from './colors';
import localStorage from './local-storage';

TerminalEmulator.loadAddon('fit');

const popoutEmulatorFile = path.resolve(__dirname, 'popout-emulator.html');

const heightKey = 'learn-ide:currentTerminalHeight'
const fontKey = 'learn-ide:currentFontSize'

const verticalLimit = 100;
const defaultHeight = 275;
const defaultFontSize = atom.config.defaultSettings.editor.fontSize;

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
  }

  attach() {
    atom.workspace.addBottomPanel({item: this});
    this.emulator.open(this.element, true);
    this.restoreHeightAndFontSize()
  }

  subscribe() {
    this.emulator.attachCustomKeydownHandler(e => {
      this.catchSaveShortcutOnWindowsOrLinux(e);
    })

    this.emulator.on('data', data => {
      this.sendToTerminal(data, event);
    });

    this.terminal.on('message', msg => {
      this.writeToEmulator(msg);
    });

    bus.on('popout-emulator:data', data => {
      this.sendToTerminal(data);
    });

    this.on('mousedown', '.terminal-resize-handle', e => {
      this.resizeByDragStarted(e);
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

  catchSaveShortcutOnWindowsOrLinux(e) {
    var {which, ctrlKey} = e;

    if (ctrlKey && (which === 83) && (process.platform !== 'darwin')) {
      // ctrl-s on win32 or linux
      var view = atom.views.getView(atom.workspace);
      atom.commands.dispatch(view, 'learn-ide:save');

      e.preventDefault()
    }
  }

  loadPopoutEmulator() {
    return new Promise((resolve) => {
      localStorage.set('popout-emulator:css', colors.getCSS());

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

  currentFontSize() {
    return parseInt(this.css('font-size'));
  }

  setFontFamily(fontFamily) {
    var value = 'courier-new, courier, monospace';

    if (fontFamily.length) { value = `${fontFamily}, ${value}` }

    $(this.emulator.element).css('font-family', value)

    this.fit()
  }

  increaseFontSize() {
    this.setFontSize(this.currentFontSize() + 2);
  }

  decreaseFontSize() {
    var currentSize = this.currentFontSize();

    if (currentSize > 2) {
      this.setFontSize(currentSize - 2);
    }
  }

  resetFontSize() {
    var defaultSize = atom.config.defaultSettings.editor.fontSize;
    this.setFontSize(defaultSize);
  }

  setFontSize(size) {
    if (this.forcedStyle) {
      this.forcedStyle.dispose()
      delete this.forcedStyle
    }

    localStorage.set(fontKey, size)
    this.css('font-size', size);

    this.fit()
  }

  forceFontSize(size) {
    var classList = Array.from(this.element.classList);
    var selector  = `.${classList.join('.')}`;
    var css       = `${selector} { font-size: ${size}px !important }`;

    this.forcedStyle = atom.styles.addStyleSheet(css);
  }

  restoreHeightAndFontSize() {
    var height   = localStorage.get(heightKey) || defaultHeight;
    var fontSize = localStorage.get(fontKey) || defaultFontSize;

    this.forceFontSize(fontSize)
    this.setHeightWithFit(height)
  }

  setHeightWithFit(desiredHeight) {
    this.height(desiredHeight)
    this.fit()
  }

  resizeByDragStarted() {
    $(document).on('mousemove', e => this.resizeAfterDrag(e))
    $(document).on('mouseup', () => this.resizeByDragStopped())
  }

  resizeByDragStopped() {
    $(document).off('mousemove', e => this.resizeAfterDrag(e))
    $(document).off('mouseup', () => this.resizeByDragStopped())
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


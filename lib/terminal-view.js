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
    this.emulator.open(this.element);
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

    localStorage.set('learn-ide:currentFontSize', size)
    this.css('font-size', size);

    this.fit()
  }

  forceFontSize(size) {
    var selector = `.${this.attr('class')}`,
        css = `${selector} { font-size: ${size}px !important }`;

    this.forcedStyle = atom.styles.addStyleSheet(css, {priority: 5});
  }

  restoreHeightAndFontSize() {
    var fontSize = localStorage.get('learn-ide:currentFontSize')
    var height = localStorage.get('learn-ide:currentTerminalHeight')

    if (fontSize) {
      this.forceFontSize(fontSize)
    }

    if (height) {
      this.height(height)
      this.emulator.fit()
    }
  }

  resizeByDragStarted() {
    $(document).on('mousemove', e => this.resizeAfterDrag(e));
    $(document).on('mouseup', () => this.resizeByDragStopped());
  }

  resizeByDragStopped() {
    $(document).off('mousemove', e => this.resizeAfterDrag(e));
    $(document).off('mouseup', () => this.resizeByDragStopped());
  }

  resizeAfterDrag({pageY, which}) {
    if (which !== 1) {
      this.resizeByDragStopped()
      return
    }

    var height = (this.outerHeight() + this.offset().top) - pageY;
    if ((height < 100) && (height < this.height())) { return }

    this.height(height)
    this.fit()
  }

  fit() {
    this.emulator.fit();

    var emulatorHeight = $(this.emulator.rowContainer).height();
    var newHeight = emulatorHeight + this.resizeHandle.height();

    this.height(newHeight);
    localStorage.set('learn-ide:currentTerminalHeight', newHeight)
  }
}

export default TerminalView


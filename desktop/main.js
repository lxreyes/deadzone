// DEADZONE — Electron main process.
//
// Boots a Chromium window pointed at the game's index.html and hides the
// default menu bar. The game is a single self-contained HTML file with no
// dependencies (see ../CLAUDE.md), so nothing else needs bundling.
//
// Behaviour:
//   - Fixed initial size matches the game's internal canvas (1200x680).
//   - useContentSize: true so those dimensions are the RENDER area, not
//     the window chrome. On Windows the title bar isn't counted.
//   - F11 toggles fullscreen (the game's canvas stays 1200x680 internally
//     and the browser scales it up with letterboxing — same as web).
//   - No menu bar / dev tools in packaged builds so the app feels native.

const { app, BrowserWindow, globalShortcut } = require('electron');
const path = require('path');
const fs = require('fs');

// In dev (`npm start`) index.html lives at ../index.html. In a packaged
// build electron-builder copies it into the app resources next to main.js.
// Prefer the local copy so shipped builds don't need any parent directory.
function resolveIndexPath() {
  const localPath = path.join(__dirname, 'index.html');
  if (fs.existsSync(localPath)) return localPath;
  return path.join(__dirname, '..', 'index.html');
}

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 680,
    useContentSize: true,
    minWidth: 640,
    minHeight: 480,
    autoHideMenuBar: true,
    backgroundColor: '#0a0a12',
    title: 'DEADZONE',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
    },
  });

  win.setMenuBarVisibility(false);
  win.loadFile(resolveIndexPath());

  // F11 → fullscreen toggle. The game's fitCanvas() handles scaling.
  win.webContents.on('before-input-event', (e, input) => {
    if (input.type === 'keyDown' && input.key === 'F11') {
      win.setFullScreen(!win.isFullScreen());
      e.preventDefault();
    }
    // F12 opens dev tools in unpackaged builds only.
    if (!app.isPackaged && input.type === 'keyDown' && input.key === 'F12') {
      win.webContents.toggleDevTools();
      e.preventDefault();
    }
  });
}

app.whenReady().then(() => {
  createWindow();
  // macOS convention: recreate window when the dock icon is clicked
  // with no windows open.
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

// Non-macOS: quit when all windows are closed.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// Release any global shortcuts on quit.
app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

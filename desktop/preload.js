// DEADZONE preload — intentionally minimal.
//
// Electron best practice is to keep contextIsolation: true and route any
// renderer ↔ main bridges through a preload script. Today the game runs
// pure in the renderer (no filesystem, no OS integration) so this file is
// a placeholder.
//
// Future hooks that would live here:
//   - Steam SDK bridge (achievements, cloud saves, overlay) via a native
//     addon like greenworks or steamworks.js
//   - File-based save export / import (dialog boxes for load / save slots)
//   - Update-check ping to a hosted manifest
//
// When you add one, expose a small typed API via contextBridge:
//   const { contextBridge, ipcRenderer } = require('electron');
//   contextBridge.exposeInMainWorld('deadzone', {
//     unlockAchievement: (id) => ipcRenderer.invoke('steam:unlock', id),
//   });

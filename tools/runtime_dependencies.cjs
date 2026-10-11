// Build-time dependencies only; no game or installed-mod access.
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const bundled = path.join(os.homedir(), '.cache', 'codex-runtimes', 'codex-primary-runtime', 'dependencies');

function getSharp() {
  try { return require('sharp'); }
  catch (error) {
    if (error.code !== 'MODULE_NOT_FOUND') throw error;
    const modulePath = process.env.DBF_HUD_SHARP_MODULE || path.join(bundled, 'node', 'node_modules', 'sharp');
    if (process.env.DBF_HUD_SHARP_MODULE || fs.existsSync(modulePath)) return require(modulePath);
    throw new Error('Sharp is required. Install sharp for Node.js or set DBF_HUD_SHARP_MODULE to its module path.');
  }
}

function pythonCommand() {
  if (process.env.DBF_HUD_PYTHON) return { command: process.env.DBF_HUD_PYTHON, args: [] };
  const executable = path.join(bundled, 'python', process.platform === 'win32' ? 'python.exe' : 'bin/python3');
  if (fs.existsSync(executable)) return { command: executable, args: [] };
  return process.platform === 'win32' ? { command: 'py', args: ['-3'] } : { command: 'python3', args: [] };
}

function execPython(args, options) {
  const python = pythonCommand();
  return execFileSync(python.command, [...python.args, ...args], options);
}

module.exports = { getSharp, pythonCommand, execPython };

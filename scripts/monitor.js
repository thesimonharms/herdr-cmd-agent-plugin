#!/usr/bin/env node
// Poll a Herdr pane and report cmd state via `herdr pane report-agent`.
// Usage: node monitor.js <pane_id> <herdr_bin>
import { spawnSync } from 'node:child_process';

const paneId = process.argv[2];
const herdrBin = process.argv[3] || process.env.HERDR_BIN_PATH || 'herdr';
if (!paneId) {
  console.error('monitor.js: missing pane_id');
  process.exit(1);
}

function readPane() {
  const r = spawnSync(herdrBin, ['pane', 'read', paneId, '--source', 'recent-unwrapped', '--lines', '60'], { encoding: 'utf8' });
  if (r.status !== 0) return '';
  try {
    const j = JSON.parse(r.stdout);
    return j.result?.text ?? r.stdout;
  } catch {
    return r.stdout;
  }
}

function report(state) {
  spawnSync(herdrBin, ['pane', 'report-agent', paneId, '--source', 'herdr:cmd', '--agent', 'cmd', '--state', state], { stdio: 'ignore' });
}

let last = '';
function classify(text) {
  if (/Do you trust the files in this folder\?/.test(text)) return 'blocked';
  if (/Do you want to/.test(text) && /1\.\s*Yes/.test(text)) return 'blocked';
  if (/Do you want to/.test(text) && /Yes.*No/.test(text)) return 'blocked';
  if (/esc to interrupt/.test(text)) return 'working';
  if (/◇\s+\S+…/.test(text)) return 'working';
  if (/[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⠶]\s+\S/.test(text) && /esc to/.test(text)) return 'working';
  if (/❯\s+Ask your question/.test(text)) return 'idle';
  if (/\? for shortcuts/.test(text)) return 'idle';
  if (/✻\s+Worked for/.test(text)) return 'idle';
  return null;
}

setInterval(() => {
  const text = readPane();
  const state = classify(text);
  if (state && state !== last) {
    last = state;
    report(state);
  } else if (state && state !== 'idle') {
    // Re-report working/blocked periodically so Herdr doesn't stale
    report(state);
  }
}, 700);

// Initial idle
report('idle');

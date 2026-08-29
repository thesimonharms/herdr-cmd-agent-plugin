/**
 * Herdr integration for CommandCode (cmd).
 * Reports idle/working/blocked to the parent Herdr pane so the sidebar
 * and `herdr agent` commands reflect cmd state.
 *
 * Install: mkdir -p ~/.commandcode/mods/herdr && cp herdr.ts ~/.commandcode/mods/herdr/index.ts
 *   or: cmd mods add /path/to/herdr-cmd-agent-plugin/cmd-mod --user
 */

import type {ModApi} from '@commandcode/harness';
import {spawn, spawnSync} from 'node:child_process';

function herdrReport(state: 'idle' | 'working' | 'blocked' | 'unknown', message?: string) {
  const paneId = process.env.HERDR_PANE_ID;
  const herdrBin = process.env.HERDR_BIN_PATH ?? 'herdr';
  if (!paneId || !herdrBin) return;
  const args = [
    'pane', 'report-agent', paneId,
    '--source', 'herdr:cmd',
    '--agent', 'cmd',
    '--state', state,
  ];
  if (message) args.push('--message', message);
  const child = spawn(herdrBin, args, {stdio: 'ignore', detached: false});
  child.on('error', () => {});
}

function classifyPaneBuffer(text: string): 'blocked' | 'working' | 'idle' | null {
  if (/Do you trust the files in this folder\?/.test(text)) return 'blocked';
  if (/Do you want to/.test(text) && /1\.\s*Yes/.test(text)) return 'blocked';
  if (/Do you want to/.test(text) && /Yes.*No/.test(text)) return 'blocked';
  if (/esc to interrupt/.test(text)) return 'working';
  if (/◇\s+\S+…/.test(text)) return 'working';
  if (/[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⠶]\s+\S/.test(text) && /esc to/.test(text)) return 'working';
  if (/❯\s+Ask your question/.test(text) && !/esc to interrupt/.test(text)) return 'idle';
  if (/\? for shortcuts/.test(text) && !/Do you want to/.test(text)) return 'idle';
  return null;
}

export default function (cmd: ModApi): void {
  try { herdrReport('idle'); } catch {}

  cmd.on('run_start', () => herdrReport('working'));
  cmd.on('tool_running', () => herdrReport('working'));
  cmd.on('subagent_start', () => herdrReport('working'));

  cmd.on('run_end', () => herdrReport('idle'));
  cmd.on('subagent_stop', () => herdrReport('idle'));
  cmd.on('interrupted', () => herdrReport('idle'));

  cmd.on('notice', (payload: unknown) => {
    try {
      const text = typeof payload === 'string' ? payload : JSON.stringify(payload ?? '');
      if (/permission|approval|Do you want to|trust the files/i.test(text)) {
        herdrReport('blocked', text.slice(0, 200));
      }
    } catch {}
  });

  cmd.on('session_shutdown', () => herdrReport('idle'));

  const paneId = process.env.HERDR_PANE_ID;
  const herdrBin = process.env.HERDR_BIN_PATH ?? 'herdr';
  if (paneId && herdrBin) {
    let last: string | null = null;
    setInterval(() => {
      try {
        const r = spawnSync(herdrBin, ['pane', 'read', paneId, '--source', 'recent-unwrapped', '--lines', '60'], {encoding: 'utf8'});
        let raw = r.stdout;
        try {
          const parsed: unknown = JSON.parse(r.stdout);
          if (parsed && typeof parsed === 'object' && 'result' in parsed) {
            const result = parsed.result;
            if (result && typeof result === 'object' && 'text' in result) {
              const textValue = result.text;
              if (typeof textValue === 'string') raw = textValue;
            }
          }
        } catch {}
        const next = classifyPaneBuffer(raw);
        if (next && next !== last) {
          last = next;
          herdrReport(next);
        } else if (next === 'blocked' || next === 'working') {
          herdrReport(next);
        }
      } catch {}
    }, 800);
  }
}

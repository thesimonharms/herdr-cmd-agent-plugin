import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

const toml = readFileSync(new URL('../agent-detection/cmd.toml', import.meta.url), 'utf8');

function mustContain(str, label) {
  assert.ok(toml.includes(str), `missing ${label}: ${str}`);
}

mustContain('id = "cmd"', 'id');
mustContain('aliases = ["commandcode"', 'aliases');
mustContain('state = "blocked"', 'blocked state');
mustContain('state = "working"', 'working state');
mustContain('state = "idle"', 'idle state');
mustContain('esc to interrupt', 'working esc');
mustContain('Do you trust the files', 'trust blocked');
mustContain('Do you want to', 'permission blocked');
mustContain('Ask your question', 'idle prompt');

console.log('manifest.test: ok');

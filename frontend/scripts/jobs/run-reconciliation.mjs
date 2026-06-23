#!/usr/bin/env node
import fs from 'node:fs';

function loadEnv(filePath) {
  if (!fs.existsSync(filePath)) return;
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#') || !trimmed.includes('=')) continue;
    const idx = trimmed.indexOf('=');
    const key = trimmed.slice(0, idx).trim();
    const value = trimmed.slice(idx + 1).trim().replace(/^['"]|['"]$/g, '');
    if (process.env[key] === undefined) process.env[key] = value;
  }
}

loadEnv('.env');
loadEnv('.env.local');

const apiBase = process.env.RECONCILIATION_API_BASE || 'http://localhost:3000';
const token = process.env.PAYMENT_INTERNAL_TOKEN || '';
const runType = process.argv[2] || 'full';

if (!token) {
  console.error('PAYMENT_INTERNAL_TOKEN is required for reconciliation cron script');
  process.exit(1);
}

const response = await fetch(`${apiBase.replace(/\/$/, '')}/api/reconciliation/run`, {
  method: 'POST',
  headers: {
    'content-type': 'application/json',
    'x-internal-token': token,
  },
  body: JSON.stringify({ run_type: runType }),
});

if (!response.ok) {
  const body = await response.text();
  console.error(`Reconciliation run failed (${response.status}): ${body}`);
  process.exit(1);
}

const data = await response.json();
console.log(JSON.stringify(data, null, 2));

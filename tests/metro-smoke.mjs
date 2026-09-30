import { spawn } from 'node:child_process';
import { mkdir, writeFile } from 'node:fs/promises';
import { chromium } from '@playwright/test';

await mkdir('evidence', { recursive: true });
const server = spawn(process.execPath, ['node_modules/expo/bin/cli', 'start', '--web', '--port', '4180'], {
  env: { ...process.env, CI: '1', EXPO_NO_TELEMETRY: '1' },
  stdio: ['ignore', 'pipe', 'pipe'],
});
let log = '';
server.stdout.on('data', chunk => { log += chunk; });
server.stderr.on('data', chunk => { log += chunk; });
let browser;
try {
  let ready = false;
  for (let i = 0; i < 90; i++) {
    if (server.exitCode !== null) throw new Error(`Metro exited: ${server.exitCode}`);
    try { if ((await fetch('http://127.0.0.1:4180')).ok) { ready = true; break; } } catch {}
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  if (!ready) throw new Error('Metro did not start within 90 seconds');
  browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto('http://127.0.0.1:4180');
  await page.getByText('今天的小事', { exact: true }).waitFor({ timeout: 60000 });
  await page.getByRole('button', { name: '新增紀錄', exact: true }).click();
  await page.getByLabel('標題', { exact: true }).fill('Windows Metro 實測');
  await page.getByRole('button', { name: '儲存', exact: true }).click();
  await page.getByText('Windows Metro 實測', { exact: true }).waitFor();
  await page.reload();
  await page.getByText('Windows Metro 實測', { exact: true }).waitFor();
  await page.screenshot({ path: `evidence/${process.platform}-metro.png`, fullPage: true });
  await writeFile('evidence/metro.json', JSON.stringify({ platform: process.platform, node: process.version, started: true, createAndReload: true, at: new Date().toISOString() }, null, 2));
} finally {
  await browser?.close();
  server.kill();
  await writeFile('evidence/metro.log', log);
}

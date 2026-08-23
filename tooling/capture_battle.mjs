import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';

const url = process.env.CAPTURE_URL ?? 'http://127.0.0.1:8080/?capture=battle';
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
page.on('console', (message) => console.log(`[browser:${message.type()}] ${message.text()}`));
page.on('pageerror', (error) => console.log(`[pageerror] ${error.message}`));

try {
  await mkdir('artifacts', { recursive: true });
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(20000);
  console.log(`Flutter DOM length: ${(await page.content()).length}`);
  await page.screenshot({ path: 'artifacts/battle.png', fullPage: false });
  console.log(`Captured ${url} at 390x844`);
} finally {
  await browser.close();
}

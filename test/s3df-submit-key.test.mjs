import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import test, { after, before } from 'node:test';

import {
  findRefreshTarget,
  normalizeFingerprint,
  refreshRegisteredKey,
  RefreshTargetNotFoundError,
} from '../scripts/s3df-submit-key.mjs';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

let browser;

before(async () => {
  browser = await chromium.launch({ channel: 'chrome', headless: true });
});

after(async () => {
  await browser?.close();
});

async function pageWithKeyRows() {
  const page = await browser.newPage();
  await page.setContent(`
    <table>
      <thead>
        <tr><th>finger_print</th><th>valid_until</th><th>action</th></tr>
      </thead>
      <tbody>
        <tr data-key="other">
          <td>SHA256:other.fingerprint</td>
          <td class="status">expired</td>
          <td><button type="button">Refresh</button></td>
        </tr>
        <tr data-key="target">
          <td>SHA256:target.fingerprint</td>
          <td class="status">expired</td>
          <td>
            <button
              type="button"
              onclick="this.closest('tr').querySelector('.status').textContent='valid until tomorrow'"
            >Refresh</button>
          </td>
        </tr>
      </tbody>
    </table>
  `);
  return page;
}

test('normalizes OpenSSH fingerprint characters to the S3DF display form', () => {
  assert.equal(
    normalizeFingerprint('SHA256:abc/def+ghi'),
    'SHA256:abc.def.ghi',
  );
});

test('finds exactly the Refresh button in the matching fingerprint row', async () => {
  const page = await pageWithKeyRows();
  try {
    const target = await findRefreshTarget(page, 'SHA256:target/fingerprint');
    assert.equal(target.fingerprint, 'SHA256:target.fingerprint');
    assert.equal(await target.row.getAttribute('data-key'), 'target');
    assert.equal(await target.refreshButton.innerText(), 'Refresh');
  } finally {
    await page.close();
  }
});

test('does not accept a partial fingerprint match', async () => {
  const page = await pageWithKeyRows();
  try {
    await assert.rejects(
      findRefreshTarget(page, 'SHA256:target'),
      RefreshTargetNotFoundError,
    );
  } finally {
    await page.close();
  }
});

test('dry-run locates the row without clicking Refresh', async () => {
  const page = await pageWithKeyRows();
  try {
    const result = await refreshRegisteredKey(page, 'SHA256:target.fingerprint', {
      dryRun: true,
    });
    assert.equal(result.dryRun, true);
    assert.equal(
      await page.locator('tr[data-key="target"] .status').innerText(),
      'expired',
    );
  } finally {
    await page.close();
  }
});

test('refresh clicks only the matching row and observes its update', async () => {
  const page = await pageWithKeyRows();
  try {
    const result = await refreshRegisteredKey(page, 'SHA256:target.fingerprint');
    assert.equal(result.changed, true);
    assert.equal(
      await page.locator('tr[data-key="target"] .status').innerText(),
      'valid until tomorrow',
    );
    assert.equal(
      await page.locator('tr[data-key="other"] .status').innerText(),
      'expired',
    );
  } finally {
    await page.close();
  }
});

test('reports a distinct not-found error for register fallback', async () => {
  const page = await pageWithKeyRows();
  try {
    await assert.rejects(
      findRefreshTarget(page, 'SHA256:missing.fingerprint'),
      RefreshTargetNotFoundError,
    );
  } finally {
    await page.close();
  }
});

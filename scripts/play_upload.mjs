#!/usr/bin/env node
/**
 * Play Developer API 上傳工具（service account JWT → access token，只用 Node 內建模組）。
 * 2026-11-15 自 JackCompass scripts/play_upload.mjs 適配：PACKAGE_NAME 改本專案 applicationId、
 * 預設 release 名稱改 Jack計算機。
 *
 * 用法：
 *   node scripts/play_upload.mjs status
 *   node scripts/play_upload.mjs upload <aab 路徑> [--track internal] [--status completed|draft] [--notes "文字"]
 *
 * 憑證：預設讀 PLAY_SA_JSON 環境變數，沒有就用 DEFAULT_KEY_PATH。
 * 這把金鑰僅存本機，**絕對不要 commit**。
 */
import { readFileSync } from 'node:fs';
import { createSign } from 'node:crypto';

const DEFAULT_KEY_PATH =
  'C:\\Users\\wenhs\\Documents\\Google\\gen-lang-client-0845794124-ac909d828649.json';
const KEY_PATH = process.env.PLAY_SA_JSON || DEFAULT_KEY_PATH;
// Play API 的 /applications/<package> 認 applicationId（與 namespace 同值）。
const PACKAGE_NAME = 'com.wenhsiaoyi.jackcalculator';
const API = 'https://androidpublisher.googleapis.com/androidpublisher/v3';
// 媒體上傳（bundle/apk）走另一條前綴，少了 /upload 會被當成 JSON 解析而 400。
const UPLOAD_API = 'https://androidpublisher.googleapis.com/upload/androidpublisher/v3';
const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';

const b64url = (input) => Buffer.from(input).toString('base64url');

async function accessToken() {
  const sa = JSON.parse(readFileSync(KEY_PATH, 'utf8'));
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT', kid: sa.private_key_id };
  const claims = {
    iss: sa.client_email,
    scope: SCOPE,
    aud: sa.token_uri,
    iat: now,
    exp: now + 3600,
  };
  const unsigned = `${b64url(JSON.stringify(header))}.${b64url(JSON.stringify(claims))}`;
  const signer = createSign('RSA-SHA256');
  signer.update(unsigned);
  const jwt = `${unsigned}.${b64url(signer.sign(sa.private_key))}`;

  const res = await fetch(sa.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`取得 access token 失敗 ${res.status}: ${await res.text()}`);
  return (await res.json()).access_token;
}

async function api(token, path, init = {}) {
  return call(token, `${API}${path}`, init);
}

async function call(token, url, init = {}) {
  const res = await fetch(url, {
    ...init,
    headers: { Authorization: `Bearer ${token}`, ...(init.headers || {}) },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${init.method || 'GET'} ${url} → ${res.status}: ${text}`);
  return text ? JSON.parse(text) : null;
}

const editPath = (id, rest) => `/applications/${PACKAGE_NAME}/edits/${id}${rest}`;

async function status(token) {
  const edit = await api(token, `/applications/${PACKAGE_NAME}/edits`, { method: 'POST' });
  try {
    const tracks = await api(token, editPath(edit.id, '/tracks'));
    const summary = tracks.tracks.map((t) => ({
      track: t.track,
      releases: (t.releases || []).map((r) => ({
        name: r.name,
        status: r.status,
        versionCodes: r.versionCodes,
      })),
    }));
    console.log(JSON.stringify({ ok: true, editId: edit.id, tracks: summary }, null, 2));
  } finally {
    await api(token, editPath(edit.id), { method: 'DELETE' }).catch(() => {});
  }
}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i].startsWith('--')) {
      flags[argv[i].slice(2)] = argv[i + 1];
      i += 1;
    } else {
      positional.push(argv[i]);
    }
  }
  return { positional, flags };
}

async function upload(token, aabPath, flags) {
  const track = flags.track || 'internal';
  const releaseStatus = flags.status || 'completed';
  const bytes = readFileSync(aabPath);

  const edit = await api(token, `/applications/${PACKAGE_NAME}/edits`, { method: 'POST' });
  console.log(`edit ${edit.id} 已建立`);

  const bundle = await call(
    token,
    `${UPLOAD_API}/applications/${PACKAGE_NAME}/edits/${edit.id}/bundles?uploadType=media`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/octet-stream' },
      body: bytes,
    },
  );
  console.log(`AAB 已上傳，versionCode=${bundle.versionCode}`);

  const release = {
    name: flags.name || `Jack計算機 ${bundle.versionCode}`,
    versionCodes: [String(bundle.versionCode)],
    status: releaseStatus,
  };
  if (flags.notes) release.releaseNotes = [{ language: flags.lang || 'zh-TW', text: flags.notes }];

  await api(token, editPath(edit.id, `/tracks/${track}`), {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ track, releases: [release] }),
  });
  console.log(`軌道 ${track} 已指向 versionCode=${bundle.versionCode}（status=${releaseStatus}）`);

  const committed = await api(token, editPath(edit.id, ':commit'), { method: 'POST' });
  console.log(`edit 已 commit：${committed.id}`);
  console.log(JSON.stringify({ ok: true, track, versionCode: bundle.versionCode }, null, 2));
}

const [command, ...rest] = process.argv.slice(2);
const { positional, flags } = parseArgs(rest);

try {
  const token = await accessToken();
  if (command === 'status') {
    await status(token);
  } else if (command === 'upload') {
    if (!positional[0]) throw new Error('用法：node scripts/play_upload.mjs upload <aab 路徑>');
    await upload(token, positional[0], flags);
  } else {
    throw new Error(`未知子命令：${command}（可用：status、upload）`);
  }
} catch (error) {
  console.error(error.message);
  process.exit(1);
}

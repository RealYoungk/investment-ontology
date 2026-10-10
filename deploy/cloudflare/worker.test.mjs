import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {test} from 'node:test';
const source = await readFile(new URL('./_worker.js', import.meta.url), 'utf8');
const {default: worker, handleRequest} = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
test('static assets bypass API transport', async () => {
  const response = await handleRequest(new Request('https://alfinder.kr/main.dart.js'),
    {ASSETS: {fetch: async () => new Response('asset')}}, () => assert.fail());
  assert.equal(await response.text(), 'asset');
});
test('RPC retains auth and sends a mutation exactly once to the fixed server', async () => {
  let calls = 0;
  const request = new Request('https://alfinder.kr/api/membership/cancel?endpoint=attacker', {
    method: 'POST', body: '{}', headers: {'content-type': 'application/json',
      authorization: 'test-only', cookie: 'session=test', origin: 'https://alfinder.kr',
      'x-serverpod-auth-mode': 'header', 'x-attacker': 'drop'},
  });
  const response = await handleRequest(request, {}, async (url, options) => {
    calls++;
    assert.equal(url, 'https://alfinder-api.49.247.192.41.sslip.io/api/membership/cancel');
    assert.equal(options.headers.get('authorization'), 'test-only');
    assert.equal(options.headers.get('cookie'), 'session=test');
    assert.equal(options.headers.get('origin'), 'https://alfinder.kr');
    assert.equal(options.headers.get('x-serverpod-auth-mode'), 'header');
    assert.equal(options.headers.get('x-attacker'), null);
    assert.equal(options.redirect, 'manual');
    assert.equal(await new Response(options.body).text(), '{}');
    throw new Error('lost upstream response');
  });
  assert.equal(calls, 1);
  assert.equal(response.status, 503);
  assert.equal(response.headers.get('cache-control'), 'no-store');
});
test('upstream errors and cookies survive without caching', async () => {
  const cookies = new Headers({'cache-control': 'public', connection: 'keep-alive'});
  cookies.append('set-cookie', 'a=test; Secure; HttpOnly');
  cookies.append('set-cookie', 'b=test; Secure; HttpOnly');
  const response = await handleRequest(new Request('https://alfinder.kr/api/membership/status'), {},
    async () => new Response('auth required', {status: 401, headers: cookies}));
  assert.equal(response.status, 401);
  assert.equal(response.headers.get('cache-control'), 'no-store');
  assert.equal(response.headers.get('connection'), null);
  assert.equal(response.headers.getSetCookie().length, 2);
});
test('malformed API paths never reach the server', async () => {
  for (const path of ['/api', '/api/foo%2fbar', '/api/a..b', '/api/']) {
    assert.equal((await handleRequest(new Request('https://alfinder.kr' + path), {},
      () => assert.fail())).status, 400);
  }
});

test('runtime execution context is not used as the HTTP client', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = async () => new Response('ok');
  try {
    const response = await worker.fetch(new Request('https://alfinder.kr/api/company/overview'), {}, {waitUntil() {}});
    assert.equal(response.status, 200);
    assert.equal(await response.text(), 'ok');
  } finally { globalThis.fetch = original; }
});

test('public entry opens the application without a methodology gate', async () => {
  for (const path of ['/', '/index.html']) {
    let served;
    const response = await handleRequest(new Request('https://alfinder.kr' + path),
      {ASSETS: {fetch: async request => { served = new URL(request.url).pathname; return new Response('<article>Publisher content</article>'); }}}, () => assert.fail());
    assert.equal(served, '/home');
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('cache-control'), 'no-store');
    assert.match(await response.text(), /Publisher content/);
  }
});

test('interactive deep links still use the existing application asset routing', async () => {
  let served;
  await handleRequest(new Request('https://alfinder.kr/company/00126380'),
    {ASSETS: {fetch: async request => { served = request.url; return new Response('application'); }}}, () => assert.fail());
  assert.equal(served, 'https://alfinder.kr/company/00126380');
});

test('membership plans do not collide with the Pages-normalized legal HTML', async () => {
  for (const [path, assetPath] of [['/membership', '/home'], ['/membership.html', '/membership']]) {
    let served;
    const response = await handleRequest(new Request('https://alfinder.kr' + path),
      {ASSETS: {fetch: async request => { served = new URL(request.url).pathname; return new Response(assetPath); }}}, () => assert.fail());
    assert.equal(served, assetPath);
    assert.equal(await response.text(), assetPath);
    assert.equal(response.headers.get('cache-control'), 'no-store');
  }
  const routes = JSON.parse(await readFile(new URL('./_routes.json', import.meta.url), 'utf8'));
  assert.ok(routes.include.includes('/membership'));
  assert.ok(routes.include.includes('/membership.html'));
});

// Logo traffic must remain static; no billable Function invocation route.
test('bundled company logos bypass Functions routes and upstream transport', async () => {
  const path = '/assets/assets/company_logos/000660.webp';
  const routes = JSON.parse(await readFile(new URL('./_routes.json', import.meta.url), 'utf8'));
  const matches = (pattern) => pattern.endsWith('*') ? path.startsWith(pattern.slice(0, -1)) : path === pattern;
  assert.equal(routes.include.some(matches), false);
  const response = await handleRequest(new Request('https://alfinder.kr' + path),
    {ASSETS: {fetch: async () => new Response('logo')}}, () => assert.fail('logo reached the backend'));
  assert.equal(await response.text(), 'logo');
  const headers = await readFile(new URL('./_headers', import.meta.url), 'utf8');
  assert.match(headers, /\/assets\/assets\/company_logos\/\*\n  Cache-Control: public, max-age=86400/);
});

test('company vector assets remain static and cached', async () => {
  const path = '/assets/assets/company_icons/420770.svg';
  const routes = JSON.parse(await readFile(new URL('./_routes.json', import.meta.url), 'utf8'));
  assert.equal(routes.include.some(pattern => pattern.endsWith('*') ? path.startsWith(pattern.slice(0, -1)) : path === pattern), false);
  const response = await handleRequest(new Request('https://alfinder.kr' + path),
    {ASSETS: {fetch: async () => new Response('<svg/>')}}, () => assert.fail('vector reached backend'));
  assert.equal(await response.text(), '<svg/>');
  const headers = await readFile(new URL('./_headers', import.meta.url), 'utf8');
  assert.ok(headers.includes('/assets/assets/company_icons/*\n  Cache-Control: public, max-age=86400'));
});

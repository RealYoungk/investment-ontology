import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {test} from 'node:test';
const source = await readFile(new URL('./_worker.js', import.meta.url), 'utf8');
const {handleRequest} = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
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

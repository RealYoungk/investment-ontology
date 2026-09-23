const {test} = require('node:test');
const assert = require('node:assert/strict');
const {PassThrough, Readable, Writable} = require('node:stream');
const vm = require('node:vm');
const fs = require('node:fs');

test('proxy retries DNS only and preserves auth headers, body, status and cookies', async () => {
  let resolutions = 0, requests = 0, options, body = '';
  const context = {module: {exports: {}}, URL, require(name) {
    if (name === 'node:dns') return {promises: {resolve4: async () => {
      if (++resolutions < 3) throw new Error('temporary DNS');
      return ['192.0.2.1'];
    }}};
    if (name === 'node:https') return {request(opts, callback) {
      requests++; options = opts;
      const upstream = new PassThrough();
      upstream.on('data', chunk => body += chunk);
      upstream.on('finish', () => {
        const response = Readable.from(['{"ok":true}']);
        response.statusCode = 200;
        response.headers = {'set-cookie': ['refresh=example; HttpOnly; Secure; Path=/api/'], 'content-type':'application/json'};
        callback(response);
      });
      return upstream;
    }};
    throw new Error(name);
  }};
  vm.runInNewContext(fs.readFileSync('deploy/api-proxy.cjs','utf8'), context);
  const req = Readable.from(['{"password":"test-only"}']);
  req.url = '/api-proxy?endpoint=emailIdp/login'; req.method = 'POST';
  req.headers = {'content-type':'application/json', cookie:'refresh=example', origin:'https://alfinder.kr', 'x-serverpod-auth-mode':'cookie', 'x-serverpod-base-path':'/api/', 'x-untrusted':'omit'};
  let result = ''; const headers = {};
  const res = new Writable({write(chunk, _enc, cb) {result += chunk;cb();}});
  res.setHeader = (name,value) => headers[name] = value;
  const done = new Promise(resolve => res.on('finish',resolve));
  await context.module.exports(req,res); await done;
  assert.equal(resolutions,3); assert.equal(requests,1);
  assert.equal(options.hostname,'investment-ontology.tailb7d6da.ts.net');
  assert.equal(options.path,'/api/emailIdp/login');
  assert.equal(options.headers['x-serverpod-auth-mode'],'cookie');
  assert.equal(options.headers['x-serverpod-base-path'],'/api/');
  assert.equal(options.headers.cookie,'refresh=example');
  assert.equal(options.headers['x-untrusted'],undefined);
  assert.equal(body,'{"password":"test-only"}');
  assert.equal(res.statusCode,200); assert.equal(result,'{"ok":true}');
  assert.equal(headers['Cache-Control'],'no-store');
  assert.match(headers['set-cookie'][0],/HttpOnly; Secure; Path=\/api\//);
});

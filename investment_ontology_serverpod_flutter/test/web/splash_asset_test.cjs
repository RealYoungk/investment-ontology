const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const http = require('node:http');
const web = path.resolve(__dirname, '../../web');
const html = fs.readFileSync(path.join(web, 'index.html'), 'utf8');
const preload = html.match(/<link\b[^>]*rel="preload"[^>]*as="image"[^>]*href="([^"]+)"/)[1];
const image = html.match(/<img\b[^>]*class="mark"[^>]*src="([^"]+)"/)[1];

test('splash preload and image resolve to the root before or after base parsing', () => {
  for (const route of ['/company/00135917', '/company/brand/brand/', '/reports/115390']) {
    const document = new URL(route, 'https://alfinder.kr');
    for (const base of [document, new URL('/', document)]) {
      for (const asset of [preload, image]) {
        assert.equal(new URL(asset, base).pathname, '/brand/alfinder-glass-splash.jpg');
        assert.equal(new URL(asset, base).origin, document.origin);
      }
    }
  }
});

test('deep-route first splash requests retrieve actual JPEG rather than SPA fallback HTML', async t => {
  const bytes = fs.readFileSync(path.join(web, 'brand/alfinder-glass-splash.jpg'));
  assert.deepEqual([...bytes.subarray(0, 3)], [0xff, 0xd8, 0xff]);
  const requests = [];
  const server = http.createServer((req, res) => {
    requests.push(req.url);
    const exists = req.url === '/brand/alfinder-glass-splash.jpg';
    res.setHeader('Content-Type', exists ? 'image/jpeg' : 'text/html');
    res.end(exists ? bytes : html);
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(() => new Promise(resolve => server.close(resolve)));
  const document = new URL('/company/00135917', `http://127.0.0.1:${server.address().port}`);
  for (const asset of [preload, image]) {
    const response = await fetch(new URL(asset, document));
    assert.equal(response.headers.get('content-type'), 'image/jpeg');
    assert.deepEqual(Buffer.from(await response.arrayBuffer()), bytes);
  }
  assert.deepEqual(requests, ['/brand/alfinder-glass-splash.jpg', '/brand/alfinder-glass-splash.jpg']);
});

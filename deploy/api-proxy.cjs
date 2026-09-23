// Transport only: authentication and all business logic remain in Serverpod.
const https = require('node:https');
const dns = require('node:dns').promises;
const upstreamHost = 'investment-ontology.tailb7d6da.ts.net';
let resolvedAddresses;
let resolvedUntil = 0;
let resolving;
async function resolveUpstream() {
  if (resolvedAddresses && Date.now() < resolvedUntil) return resolvedAddresses;
  if (resolving) return resolving;
  resolving = (async () => {
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const addresses = await dns.resolve4(upstreamHost);
        if (!addresses.length) throw new Error('DNS empty');
        resolvedAddresses = addresses; resolvedUntil = Date.now() + 60000;
        return addresses;
      } catch (error) { if (attempt === 2) throw error; }
    }
  })();
  try { return await resolving; } finally { resolving = undefined; }
}

module.exports = async (req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  const endpoint = new URL(req.url, 'https://alfinder.kr').searchParams.get('endpoint') || '';
  if (!/^[a-zA-Z0-9_./-]*$/.test(endpoint) || endpoint.includes('..')) {
    res.statusCode = 400;
    return res.end('Invalid API path');
  }
  try {
    // Resolve A records explicitly instead of relying on the edge rewrite resolver.
    // Retry DNS only, before sending any request; never replay a mutation.
    const addresses = await resolveUpstream();
    const headers = {};
    for (const name of ['content-type', 'content-length', 'authorization', 'cookie', 'origin', 'accept', 'x-serverpod-auth-mode', 'x-serverpod-base-path']) {
      if (req.headers[name] !== undefined) headers[name] = req.headers[name];
    }
    const upstream = https.request({
      hostname: upstreamHost, servername: upstreamHost,
      path: '/api/' + endpoint, method: req.method, headers,
      family: 4,
      lookup: (_host, options, callback) => options.all
        ? callback(null, [{ address: addresses[0], family: 4 }])
        : callback(null, addresses[0], 4),
      timeout: 25000,
    }, (response) => {
      res.statusCode = response.statusCode;
      for (const [name, value] of Object.entries(response.headers)) {
        if (value !== undefined && !['connection', 'transfer-encoding', 'keep-alive', 'cache-control'].includes(name)) {
          res.setHeader(name, value);
        }
      }
      response.on('error', () => res.destroy());
      response.pipe(res);
    });
    upstream.on('timeout', () => upstream.destroy(new Error('Upstream timeout')));
    upstream.on('error', (error) => {
      console.error('api-proxy upstream', error.code || error.message);
      if (!res.headersSent) { res.statusCode = 503; res.end('API temporarily unavailable'); }
      else res.destroy();
    });
    req.on('aborted', () => upstream.destroy());
    req.pipe(upstream);
  } catch (error) {
    console.error('api-proxy DNS', error.code || error.message);
    res.statusCode = 503;
    res.end('API temporarily unavailable');
  }
};

// Transport only. Serverpod owns authentication, authorization and billing.
const UPSTREAM = 'https://alfinder-api.49.247.192.41.sslip.io';
const REQUEST_HEADERS = ['content-type', 'authorization', 'cookie', 'origin',
  'accept', 'x-serverpod-auth-mode', 'x-serverpod-base-path'];
const HOP_HEADERS = ['connection', 'transfer-encoding', 'keep-alive',
  'proxy-authenticate', 'proxy-authorization', 'te', 'trailer', 'upgrade'];

export async function handleRequest(request, env, send = fetch) {
  const url = new URL(request.url);
  if (url.pathname !== '/api' && !url.pathname.startsWith('/api/')) {
    return env.ASSETS.fetch(request);
  }
  const endpoint = url.pathname.slice(4);
  if (!/^\/[a-zA-Z0-9_./-]+$/.test(endpoint) || endpoint.includes('..')) {
    return new Response('Invalid API path', {status: 400});
  }
  const headers = new Headers();
  for (const name of REQUEST_HEADERS) {
    const value = request.headers.get(name);
    if (value !== null) headers.set(name, value);
  }
  try {
    // Do not forward the client host or user-selected upstream/query parameters.
    // Never retry a mutation, even if its upstream response is lost.
    const upstream = await send(UPSTREAM + '/api' + endpoint, {
      method: request.method, headers,
      body: ['GET', 'HEAD'].includes(request.method) ? undefined : request.body,
      redirect: 'manual', signal: AbortSignal.timeout(25000),
    });
    const responseHeaders = new Headers(upstream.headers);
    for (const name of HOP_HEADERS) responseHeaders.delete(name);
    responseHeaders.set('Cache-Control', 'no-store');
    responseHeaders.set('X-Content-Type-Options', 'nosniff');
    // Clone the complete Headers object to preserve multiple Set-Cookie values.
    return new Response(upstream.body, {
      status: upstream.status, statusText: upstream.statusText,
      headers: responseHeaders,
    });
  } catch (_) {
    // Do not log request bodies, credentials, payment keys or upstream responses.
    return new Response('API temporarily unavailable', {
      status: 503, headers: {'Cache-Control': 'no-store'},
    });
  }
}
export default {fetch: handleRequest};

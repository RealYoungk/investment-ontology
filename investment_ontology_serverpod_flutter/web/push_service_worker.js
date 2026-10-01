self.addEventListener('push', event => {
  let payload;
  try { payload = event.data.json(); } catch (_) { return; }
  event.waitUntil(self.registration.showNotification(String(payload.title || '투자 온톨로지'), {
    body: String(payload.body || ''), tag: String(payload.tag || 'company-update'),
    data: {path: '/watchlist'}
  }));
});
self.addEventListener('notificationclick', event => {
  event.notification.close();
  event.waitUntil((async () => {
    const url = new URL('/watchlist', self.location.origin).href;
    for (const tab of await self.clients.matchAll({type: 'window', includeUncontrolled: true})) {
      if (new URL(tab.url).origin === self.location.origin) { await tab.navigate(url); return tab.focus(); }
    }
    return self.clients.openWindow(url);
  })());
});

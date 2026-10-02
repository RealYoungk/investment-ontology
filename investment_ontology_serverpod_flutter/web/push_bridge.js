/* Explicit opt-in; the browser owns permission and its push subscription. */
(() => {
  const supported = () => window.isSecureContext && 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
  const registration = () => navigator.serviceWorker.register(new URL('push_service_worker.js', document.baseURI), {scope: new URL('./', document.baseURI).pathname});
  const subscription = async () => supported() ? (await registration()).pushManager.getSubscription() : null;
  const decode = text => Uint8Array.from(atob(text.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - text.length % 4) % 4)), c => c.charCodeAt(0));
  const disable = async () => {
    if (!supported()) return;
    const reg = await registration();
    const sub = await reg.pushManager.getSubscription();
    if (sub && !await sub.unsubscribe()) throw new Error('Unsubscribe failed');
    for (const notice of await reg.getNotifications()) notice.close();
    localStorage.removeItem('alfinderPushOwner');
  };
  window.alfinderPush = {
    status: async () => !supported() ? 'unsupported' : Notification.permission === 'denied' ? 'denied' : (await subscription()) ? 'enabled' : Notification.permission,
    endpoint: async () => (await subscription())?.endpoint ?? null,
    disable,
    enable: (key, owner) => {
      // Invoke synchronously in the click handler, before any awaited operation.
      const permission = Notification.permission === 'granted' ? Promise.resolve('granted') : Notification.requestPermission();
      return permission.then(async value => {
        if (value !== 'granted') throw new Error('Permission not granted');
        if (localStorage.getItem('alfinderPushOwner') !== owner) await disable();
        const reg = await registration();
        await navigator.serviceWorker.ready;
        const sub = await reg.pushManager.getSubscription() ?? await reg.pushManager.subscribe({userVisibleOnly: true, applicationServerKey: decode(key)});
        localStorage.setItem('alfinderPushOwner', owner);
        return JSON.stringify(sub.toJSON());
      });
    }
  };
})();

/* One manual, in-flow AdSense slot. Never auto-refresh or auto-enable Auto ads. */
(function (root) {
  'use strict';
  let scriptPromise;
  let publisherId;
  const slots = new WeakMap();
  function load(publisher) {
    if (publisherId && publisherId !== publisher) return Promise.reject(new Error('Publisher mismatch'));
    if (scriptPromise) return scriptPromise;
    publisherId = publisher;
    scriptPromise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.async = true;
      script.crossOrigin = 'anonymous';
      script.src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=' + publisher;
      const timeout = setTimeout(() => reject(new Error('Ad script timeout')), 15000);
      script.onload = () => { clearTimeout(timeout); resolve(); };
      script.onerror = () => { clearTimeout(timeout); reject(new Error('Ad script unavailable')); };
      document.head.appendChild(script);
    });
    return scriptPromise;
  }
  function dispose(element) {
    const state = slots.get(element);
    if (!state) return;
    state.disposed = true;
    state.finish(false);
    element.replaceChildren();
    slots.delete(element);
  }
  function mount(element, publisher, slot, testMode) {
    if (!/^ca-pub-[0-9]{16}$/.test(publisher) || !/^[0-9]{10}$/.test(slot)) return Promise.resolve(false);
    const existing = slots.get(element);
    if (existing) return existing.promise;
    const state = { disposed: false, observer: null, timer: null, frame: null };
    state.promise = new Promise(resolve => {
      let settled = false;
      state.finish = ok => {
        if (settled) return;
        settled = true;
        clearTimeout(state.timer);
        cancelAnimationFrame(state.frame);
        if (state.observer) state.observer.disconnect();
        resolve(ok);
      };
      state.timer = setTimeout(() => state.finish(false), 20000);
      const attach = async () => {
        if (state.disposed || settled) return;
        // Flutter creates the element before attaching it to the browser DOM.
        if (!element.isConnected || element.getBoundingClientRect().width < 250) {
          state.frame = requestAnimationFrame(attach);
          return;
        }
        try {
          await load(publisher);
          if (state.disposed || settled || !element.isConnected) return state.finish(false);
          const ad = document.createElement('ins');
          ad.className = 'adsbygoogle';
          ad.style.cssText = 'display:block;width:100%;height:100px';
          ad.setAttribute('data-ad-client', publisher);
          ad.setAttribute('data-ad-slot', slot);
          ad.setAttribute('data-ad-format', 'horizontal');
          ad.setAttribute('data-full-width-responsive', 'false');
          if (testMode) ad.setAttribute('data-adtest', 'on');
          state.observer = new MutationObserver(() => {
            const status = ad.getAttribute('data-ad-status');
            if (status === 'filled') state.finish(true);
            if (status === 'unfilled') state.finish(false);
          });
          state.observer.observe(ad, { attributes: true, attributeFilter: ['data-ad-status'] });
          element.appendChild(ad);
          (root.adsbygoogle = root.adsbygoogle || []).push({});
        } catch (_) { state.finish(false); }
      };
      state.frame = requestAnimationFrame(attach);
    });
    slots.set(element, state);
    return state.promise;
  }
  root.alfinderAds = Object.freeze({ mount, dispose });
})(window);

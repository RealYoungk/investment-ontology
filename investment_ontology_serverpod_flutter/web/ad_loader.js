/* One manual, in-flow AdSense slot. Never auto-refresh or auto-enable Auto ads. */
(function (root) {
  'use strict';
  let scriptPromise;
  let cmpScriptPromise;
  let publisherId;
  const slots = new WeakMap();
  const active = new Set();
  root.addEventListener('alfinder-ad-consent', () => {
    if (root.alfinderAdConsent?.choice() !== true) {
      for (const element of [...active]) dispose(element);
    }
  });
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
  function loadCmp(publisher) {
    if (cmpScriptPromise) return cmpScriptPromise;
    cmpScriptPromise = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      script.async = true;
      // Message-only tag: AdSense itself may request inventory on load.
      script.src = 'https://fundingchoicesmessages.google.com/i/' + publisher.replace(/^ca-/, '') + '?ers=1';
      // Forward only Google's documented message-preview parameters.
      const debug = new URLSearchParams(root.location?.search || '');
      if (debug.get('fc') === 'alwaysshow' && ['gdpr', 'ccpa', 'usnat', 'usfl'].includes(debug.get('fctype'))) {
        script.src += '&fc=alwaysshow&fctype=' + debug.get('fctype');
      }
      script.onload = resolve;
      script.onerror = () => reject(new Error('CMP script unavailable'));
      document.head.appendChild(script);
    });
    return cmpScriptPromise;
  }
  function dispose(element) {
    const state = slots.get(element);
    if (!state) return;
    state.disposed = true;
    if (state.cmpTimer) clearTimeout(state.cmpTimer);
    if (state.cmpListener && typeof root.__tcfapi === 'function') {
      root.__tcfapi('removeEventListener', 2, () => {}, state.cmpListener);
      state.cmpListener = null;
    }
    if (state.gppListener && typeof root.__gpp === 'function') {
      root.__gpp('removeEventListener', () => {}, state.gppListener);
      state.gppListener = null;
    }
    if (state.cmpResolve) state.cmpResolve(false);
    state.finish(false);
    element.replaceChildren();
    slots.delete(element);
    active.delete(element);
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
        if (!ok && state.cmpListener && typeof root.__tcfapi === 'function') {
          root.__tcfapi('removeEventListener', 2, () => {}, state.cmpListener);
          state.cmpListener = null;
        }
        if (!ok && state.cmpTimer) clearTimeout(state.cmpTimer);
        if (!ok && state.cmpResolve) state.cmpResolve(false);
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
          clearTimeout(state.timer);
          if (!root.alfinderAdConsent || !await root.alfinderAdConsent.request()) return state.finish(false);
          if (state.disposed || settled) return state.finish(false);
          if (state.disposed || settled || !element.isConnected || root.alfinderAdConsent.choice() !== true) return state.finish(false);
          // Load Google's message-only tag before any AdSense inventory code.
          // Wait for its jurisdiction and consent result; unknown/error is denied.
          const permitted = await new Promise(resolve => {
            const timer = state.cmpTimer = setTimeout(() => resolve(false), 15000);
            state.cmpResolve = resolve;
            root.googlefc = root.googlefc || {};
            root.googlefc.callbackQueue = root.googlefc.callbackQueue || [];
            root.googlefc.callbackQueue.push({'CONSENT_API_READY': () => {
              if (typeof root.__tcfapi !== 'function') { clearTimeout(timer); resolve(false); return; }
              root.__tcfapi('addEventListener', 2, (data, ok) => {
                if (state.disposed) return;
                if (data?.listenerId) state.cmpListener = data.listenerId;
                if (!ok || !data || data.cmpStatus === 'error') {
                  clearTimeout(timer); resolve(false); dispose(element); return;
                }
                if (data.eventStatus === 'cmpuishown') {
                  // A reopened consent UI invalidates the previous decision.
                  // The initial UI keeps its deadline; late callbacks cannot push.
                  if (state.cmpPermitted) dispose(element);
                  return;
                }
                // Google's non-GDPR callback can omit eventStatus entirely.
                const outsideGdpr = data.gdprApplies === false && data.cmpStatus === 'loaded';
                if (!outsideGdpr && !['tcloaded', 'useractioncomplete'].includes(data.eventStatus)) return;
                if (typeof data.gdprApplies !== 'boolean') {
                  if (state.cmpPermitted) dispose(element);
                  return;
                }
                const allowed = data.gdprApplies === false ||
                  (data.cmpId === 300 && data.purpose?.consents?.[1] === true && data.vendor?.consents?.[755] === true);
                if (data.gdprApplies === false && allowed) {
                  // GDPR does not determine US opt-out. Google's explicit US
                  // result is required; absent/unknown APIs retain the deadline.
                  root.googlefc.callbackQueue.push({'INITIAL_US_STATES_OPT_OUT_DATA_READY': () => {
                    if (state.disposed) return;
                    let status;
                    try { status = root.googlefc.usstatesoptout?.getInitialUsStatesOptOutStatus(); }
                    catch (_) { dispose(element); return; }
                    if (root.navigator?.globalPrivacyControl === true || status === 3 || status === 0) {
                      clearTimeout(timer); resolve(false); dispose(element); return;
                    }
                    if (status === 1) {
                      state.cmpPermitted = true;
                      clearTimeout(timer); resolve(true); return;
                    }
                    if (status !== 2 || typeof root.__gpp !== 'function') return;
                    root.__gpp('addEventListener', (event, ok) => {
                      if (state.disposed) return;
                      if (event?.listenerId) state.gppListener = event.listenerId;
                      const ping = event?.pingData;
                      if (!ok || event?.eventName === 'error' ||
                          (state.cmpPermitted && (ping?.cmpStatus !== 'loaded' || event?.eventName === 'sectionChange' ||
                            ping?.signalStatus !== 'ready' || ping?.cmpDisplayStatus === 'visible'))) {
                        clearTimeout(timer); resolve(false); dispose(element); return;
                      }
                      if (ping?.cmpStatus !== 'loaded' || ping?.signalStatus !== 'ready' ||
                          ping?.cmpDisplayStatus === 'visible') return;
                      // Google's initial status is cached for the pageview.
                      // Remounts must read the current parsed opt-out signals.
                      const sections = Object.entries(ping.parsedSections || {})
                        .filter(([name]) => name.startsWith('us'))
                        .flatMap(([, value]) => Array.isArray(value) ? value : [value]);
                      const choices = sections.flatMap(section =>
                        ['SaleOptOut', 'SharingOptOut', 'TargetedAdvertisingOptOut']
                          .filter(key => Object.prototype.hasOwnProperty.call(section || {}, key))
                          .map(key => section[key]));
                      if (sections.some(section => section?.Gpc === true || section?.Gpc === 1) ||
                          choices.some(value => value === 1)) {
                        clearTimeout(timer); resolve(false); dispose(element); return;
                      }
                      if (!choices.length || choices.some(value => ![0, 2].includes(value))) return;
                      state.cmpPermitted = true;
                      clearTimeout(timer); resolve(true);
                    });
                  }});
                  return;
                }
                state.cmpPermitted = allowed;
                clearTimeout(timer); resolve(allowed);
                if (!allowed) dispose(element);
              });
            }});
            loadCmp(publisher).catch(() => { clearTimeout(timer); resolve(false); dispose(element); });
          });
          if (!permitted || state.disposed || settled || root.alfinderAdConsent.choice() !== true) return state.finish(false);
          await load(publisher);
          if (state.disposed || settled || !element.isConnected || root.alfinderAdConsent.choice() !== true) return state.finish(false);
          // Initial inventory is contextual/non-personalized, even after opt-in.
          (root.adsbygoogle = root.adsbygoogle || []).requestNonPersonalizedAds = 1;
          state.timer = setTimeout(() => state.finish(false), 20000);
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
          state.adRequested = true;
          (root.adsbygoogle = root.adsbygoogle || []).push({});
        } catch (_) { state.finish(false); }
      };
      state.frame = requestAnimationFrame(attach);
    });
    slots.set(element, state);
    active.add(element);
    return state.promise;
  }
  root.alfinderAds = Object.freeze({ mount, dispose });
})(window);

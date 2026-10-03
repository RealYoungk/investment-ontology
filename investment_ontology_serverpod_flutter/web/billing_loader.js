(function () {
  'use strict';
  let loading;
  let portOneLoading;
  function sdk() {
    if (window.TossPayments) return Promise.resolve();
    if (!loading) {
      loading = new Promise((resolve, reject) => {
        const node = document.createElement('script');
        node.src = 'https://js.tosspayments.com/v2/standard';
        const timer = setTimeout(() => { loading = null; node.remove(); reject(new Error('SDK timeout')); }, 12000);
        node.onload = () => { clearTimeout(timer); resolve(); };
        node.onerror = () => { clearTimeout(timer); loading = null; node.remove(); reject(new Error('SDK unavailable')); };
        document.head.appendChild(node);
      });
    }
    return loading;
  }
  window.alfinderBilling = {
    clearQuery() {
      const operation = new URL(location.href).searchParams.get('card') === 'replace' ? '?card=replace' : '';
      history.replaceState(history.state, '', location.pathname + operation);
    },
    async start(clientKey, customerKey, state, provider, storeId, channelKey, issueId) {
      if (provider === 'portone') {
        if (!storeId || !channelKey || !issueId || !state || !customerKey) throw new Error('Invalid checkout');
        if (location.protocol !== 'https:' && !['localhost', '127.0.0.1', '[::1]'].includes(new URL(location.href).hostname)) throw new Error('HTTPS required');
        if (!window.PortOne) {
          if (!portOneLoading) {
            portOneLoading = new Promise((resolve, reject) => {
              const node = document.createElement('script');
              node.src = 'https://cdn.portone.io/v2/browser-sdk.js';
              const fail = message => { portOneLoading = null; node.remove(); reject(new Error(message)); };
              const timer = setTimeout(() => fail('SDK timeout'), 12000);
              node.onload = () => {
                clearTimeout(timer);
                if (!window.PortOne?.requestIssueBillingKey) fail('SDK unavailable');
                else resolve();
              };
              node.onerror = () => { clearTimeout(timer); fail('SDK unavailable'); };
              document.head.appendChild(node);
            });
          }
          await portOneLoading;
        }
        const callback = new URL('/membership/checkout', location.origin);
        callback.searchParams.set('state', state);
        if (new URL(location.href).searchParams.get('card') === 'replace') callback.searchParams.set('card', 'replace');
        const result = await window.PortOne.requestIssueBillingKey({storeId, channelKey,
          billingKeyMethod: 'CARD', issueId, issueName: '알파인더 월간 멤버십',
          customer: {customerId: customerKey}, redirectUrl: callback.href});
        // Redirect-mode SDK may return no result while leaving this page.
        // Do not abort a valid pending checkout on that path.
        if (result === undefined) return;
        if (!result || result.code || !result.billingKey) throw new Error('Card registration incomplete');
        callback.searchParams.set('authKey', result.billingKey);
        location.assign(callback.href);
        return;
      }
      if (provider && provider !== 'toss') throw new Error('Unsupported provider');
      if (!/^(test|live)_ck_[A-Za-z0-9]+$/.test(clientKey) || !state || !customerKey) throw new Error('Invalid checkout');
      if (clientKey.startsWith('live_') && location.protocol !== 'https:') throw new Error('HTTPS required');
      await sdk();
      const callback = new URL('/membership/checkout', location.origin);
      callback.searchParams.set('state', state);
      if (new URL(location.href).searchParams.get('card') === 'replace') callback.searchParams.set('card','replace');
      await window.TossPayments(clientKey).payment({customerKey}).requestBillingAuth({
        method: 'CARD', successUrl: callback.href, failUrl: callback.href
      });
    }
  };
})();

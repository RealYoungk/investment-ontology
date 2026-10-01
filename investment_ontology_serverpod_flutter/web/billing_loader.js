(function () {
  'use strict';
  let loading;
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
    clearQuery() { history.replaceState(history.state, '', location.pathname); },
    async start(clientKey, customerKey, state) {
      if (!/^(test|live)_ck_[A-Za-z0-9]+$/.test(clientKey) || !state || !customerKey) throw new Error('Invalid checkout');
      if (clientKey.startsWith('live_') && location.protocol !== 'https:') throw new Error('HTTPS required');
      await sdk();
      const callback = new URL('/membership/checkout', location.origin);
      callback.searchParams.set('state', state);
      await window.TossPayments(clientKey).payment({customerKey}).requestBillingAuth({
        method: 'CARD', successUrl: callback.href, failUrl: callback.href
      });
    }
  };
})();

/* Test-only Google transport. Used with the real production loader and Flutter DOM. */
(function(root) {
  root.alfinderAdFixture = {cmpScripts: 0, adScripts: 0, pushes: 0};
  root.alfinderAdConsent = {choice: () => true, request: async () => true};
  root.adsbygoogle = [];
  root.adsbygoogle.push = () => {
    root.alfinderAdFixture.pushes++;
    for (const ad of document.querySelectorAll('ins.adsbygoogle')) ad.setAttribute('data-ad-status', 'filled');
  };
  root.__tcfapi = (command, _version, callback) => {
    if (command === 'addEventListener') callback({gdprApplies:false,cmpId:300,cmpStatus:'loaded',listenerId:1},true);
  };
  const append = document.head.appendChild.bind(document.head);
  document.head.appendChild = element => {
    if (element.src?.includes('fundingchoicesmessages.google.com')) {
      root.alfinderAdFixture.cmpScripts++;
      queueMicrotask(() => {
        const pending = root.googlefc.callbackQueue;
        root.googlefc.usstatesoptout = {getInitialUsStatesOptOutStatus: () => 1};
        const dispatch = item => {item.CONSENT_API_READY?.();item.INITIAL_US_STATES_OPT_OUT_DATA_READY?.();};
        root.googlefc.callbackQueue = {push: dispatch};
        for (const item of pending) dispatch(item);
        element.onload();
      });
      return element;
    }
    if (element.src?.includes('pagead2.googlesyndication.com')) {
      root.alfinderAdFixture.adScripts++;
      queueMicrotask(() => element.onload());
      return element;
    }
    return append(element);
  };
})(window);

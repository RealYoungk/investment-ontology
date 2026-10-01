/* A first-party opt-in is not a replacement for Google's certified CMP. */
(function(root) {
  'use strict';
  const key = 'alfinder.adConsent', version = '2026-10-01';
  const lifetime = 90 * 24 * 60 * 60 * 1000;
  let memory, panel, waiting = [];
  function choice() {
    let value = memory;
    try { value = JSON.parse(root.localStorage.getItem(key)); } catch (_) {}
    return value && value.version === version && value.expires > Date.now() &&
      typeof value.allowed === 'boolean' ? value.allowed : null;
  }
  function updateStatus() {
    const status = document.getElementById('ad-choice-status');
    if (status) status.textContent = choice() === true ? '광고 허용됨' : choice() === false ? '광고 거부됨' : '아직 선택하지 않았습니다. 광고를 요청하지 않습니다.';
  }
  function setChoice(allowed) {
    memory = {version, allowed, expires: Date.now() + lifetime};
    try { root.localStorage.setItem(key, JSON.stringify(memory)); } catch (_) {}
    if (panel) { panel.remove(); panel = null; }
    waiting.splice(0).forEach(resolve => resolve(allowed));
    updateStatus();
    root.dispatchEvent(new Event('alfinder-ad-consent'));
  }
  function request() {
    const current = choice();
    if (current !== null) return Promise.resolve(current);
    const promise = new Promise(resolve => waiting.push(resolve));
    if (!panel) {
      panel = document.createElement('section');
      panel.setAttribute('role', 'region');
      panel.setAttribute('aria-label', '선택 광고 안내');
      panel.style.cssText = 'position:fixed;bottom:16px;left:16px;right:16px;max-width:600px;margin:auto;z-index:10000;background:white;color:#202831;border:1px solid #dae1e7;border-radius:12px;padding:20px;font:14px/1.7 system-ui,sans-serif;box-shadow:0 4px 20px #0002;max-height:70vh;overflow:auto';
      const text = document.createElement('p');
      text.textContent = '광고를 허용하시겠어요? Google과 광고 파트너가 쿠키·IP·기기·페이지 정보를 광고 표시와 측정에 처리할 수 있습니다. 거부해도 무료 기업 정보와 계정 기능을 이용할 수 있습니다.';
      panel.appendChild(text);
      const link = document.createElement('a'); link.href = '/cookies.html'; link.textContent = '공급자·처리 정보와 선택 변경'; panel.appendChild(link);
      for (const [label, allowed] of [['광고 거부', false], ['광고 허용', true]]) {
        const button = document.createElement('button'); button.type = 'button'; button.textContent = label;
        button.style.cssText = 'font:inherit;background:white;color:#245f79;border:1px solid #245f79;border-radius:8px;padding:10px 16px;margin:12px 8px 0 0;min-height:44px;cursor:pointer';
        button.onclick = () => setChoice(allowed); panel.appendChild(button);
      }
      document.body.appendChild(panel);
    }
    return promise;
  }
  function revokeGoogle() {
    if (!root.googlefc || typeof root.googlefc.showRevocationMessage !== 'function') {
      const status = document.getElementById('ad-choice-status');
      if (status) status.textContent = '광고 요청을 중단했습니다. Google 상세 동의는 광고 기능이 연결된 화면에서 변경할 수 있습니다.';
      return;
    }
    root.googlefc.callbackQueue.push({'CONSENT_API_READY': () => root.googlefc.showRevocationMessage()});
  }
  root.addEventListener('storage', event => {
    if (event.key === 'alfinder.adSettingsRequest') { revokeGoogle(); return; }
    if (event.key !== key && event.key !== null) return;
    memory = undefined; updateStatus();
    root.dispatchEvent(new Event('alfinder-ad-consent'));
  });
  root.alfinderAdConsent = Object.freeze({choice, request, setChoice});
  const reject = document.getElementById('ad-reject'), accept = document.getElementById('ad-accept'), google = document.getElementById('ad-google');
  if (reject) reject.onclick = () => setChoice(false);
  if (accept) accept.onclick = () => setChoice(true);
  if (google) google.onclick = () => {
    setChoice(false);
    try { root.localStorage.setItem('alfinder.adSettingsRequest', String(Date.now())); } catch (_) {}
    revokeGoogle();
  };
  updateStatus();
})(window);

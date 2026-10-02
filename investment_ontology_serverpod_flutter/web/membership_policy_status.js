(function () {
  'use strict';
  const node = document.querySelector('[data-membership-status]');
  if (!node) return;
  // Public offer only. Failure retains the explicit launch-preparation notice.
  fetch('/api/membershipOffer/offer', {
    method: 'POST', credentials: 'omit', cache: 'no-store',
    headers: {'Content-Type': 'application/json'}, body: '{}',
  }).then(response => response.ok ? response.json() : null).then(offer => {
    if (offer?.paymentAvailable !== true || offer?.isTest !== false) return;
    node.textContent = '유료 멤버십을 제공합니다. 결제 전 현재 가입 요금과 자동 갱신·해지·환불 조건을 확인해주세요.';
  }).catch(() => {});
})();

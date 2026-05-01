/**
 * フェーズ1-5: 方式B（サーバー結果は window message で受信）
 * fetch の戻り値は { ok: true } のみ。payload は action ごとの message を参照。
 */

function postNui(eventName, data) {
  fetch('https://' + GetParentResourceName() + '/' + eventName, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data || {}),
  }).catch(function () {});
}

window.addEventListener('message', function (ev) {
  var msg = ev.data;
  if (!msg || typeof msg !== 'object') return;

  if (msg.action === 'open') {
    document.body.style.display = 'block';
    return;
  }

  if (
    msg.action === 'bookData' ||
    msg.action === 'deckSelected' ||
    msg.action === 'deckUpdated' ||
    msg.action === 'deckListUpdated'
  ) {
    if (typeof console !== 'undefined' && console.debug) {
      console.debug('[jp-tcgbook]', msg.action, msg.payload);
    }
  }
});

document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape') {
    postNui('closeBook', {});
    document.body.style.display = 'none';
  }
});

document.body.style.display = 'none';

/**
 * /book と /bookadmin のページ切替（同一リソース・別 HTML）
 * Lua から SendNUIMessage({ action: 'jp-tcgbook:navigate', target, resource })
 */
(function () {
  window.addEventListener('message', function (event) {
    var msg = event.data;
    if (!msg || typeof msg !== 'object') return;
    if (msg.action !== 'jp-tcgbook:navigate') return;
    var res = msg.resource;
    var target = msg.target;
    if (!res || !target) return;
    var base = 'https://cfx-nui-' + res + '/html/';
    if (target === 'admin') {
      window.location.href = base + 'admin/index.html';
    } else if (target === 'book') {
      window.location.href = base + 'index.html';
    }
  });
})();

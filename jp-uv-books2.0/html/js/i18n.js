/* ════════════════════════════════════════════════
   jp-uv-books · NUI i18n & font runtime
   ════════════════════════════════════════════════ */
(function () {
  window.__i18n = {};
  window.__cfg  = {
    maxPages: 20, maxChars: 600,
    maxTitleChars: 30, maxAuthorChars: 20, maxGenreChars: 30,
  };

  function applyI18n() {
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      var key = el.getAttribute('data-i18n');
      if (window.__i18n[key]) el.textContent = window.__i18n[key];
    });
    document.querySelectorAll('[data-i18n-ph]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-ph');
      if (window.__i18n[key]) el.placeholder = window.__i18n[key];
    });
    document.querySelectorAll('[data-i18n-title]').forEach(function (el) {
      var key = el.getAttribute('data-i18n-title');
      if (window.__i18n[key]) el.setAttribute('title', window.__i18n[key]);
    });
  }
  window.applyI18n = applyI18n;

  function applyConfig(cfg) {
    if (!cfg) return;
    window.__cfg = Object.assign(window.__cfg, cfg);
    var t = document.getElementById('coverTitleInput');
    var a = document.getElementById('coverAuthorInput');
    var g = document.getElementById('iGenreCustom');
    var s = document.getElementById('iSig');
    if (t) t.maxLength = window.__cfg.maxTitleChars;
    if (a) a.maxLength = window.__cfg.maxAuthorChars;
    if (g) g.maxLength = window.__cfg.maxGenreChars;
    if (s) s.maxLength = window.__cfg.maxAuthorChars;
  }
  window.applyConfig = applyConfig;

  window._L = function (key) {
    var s = window.__i18n[key] || key;
    for (var i = 1; i < arguments.length; i++) {
      s = s.replace('%s', arguments[i]).replace('%d', arguments[i]);
    }
    return s;
  };

  // フォントキー → CSS クラス切替（'classic-serif' / 'jp-yuji-mai' 等）
  window.applyFontClass = function (el, fontKey) {
    if (!el || !fontKey) return;
    el.className = el.className.replace(/\bf-[a-z0-9-]+\b/gi, '').trim();
    el.classList.add('f-' + fontKey);
  };

  window.addEventListener('message', function (e) {
    var d = e.data || {};
    if (d.action === 'setLocale') {
      window.__i18n = d.strings || {};
      applyConfig(d.config);
      applyI18n();
    }
  });
})();
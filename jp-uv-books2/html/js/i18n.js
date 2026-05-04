/* ════════════════════════════════════════════════
   jp-uv-books · NUI i18n & font runtime
   ════════════════════════════════════════════════ */
(function () {
  window.__i18n = {};
  window.__cfg  = {
    maxPages: 20, maxChars: 600,
    maxTitleChars: 30, maxAuthorChars: 20, maxGenreChars: 30,
    uiScale: 1,
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
    var sc = parseFloat(window.__cfg.uiScale);
    if (isNaN(sc) || sc <= 0) sc = 1;
    if (sc < 0.45) sc = 0.45;
    if (sc > 1.4) sc = 1.4;
    window.__cfg.uiScale = sc;
    document.documentElement.style.setProperty('--book-ui-scale', String(sc));
  }
  window.applyConfig = applyConfig;

  window._L = function (key) {
    var s = window.__i18n[key] || key;
    for (var i = 1; i < arguments.length; i++) {
      s = s.replace('%s', arguments[i]).replace('%d', arguments[i]);
    }
    return s;
  };

  // 原作・段階2以前の font-family 名 → 内部キー（メタデータ後方互換）
  var LEGACY_FONT_MAP = {
    'Palatino Linotype': 'classic-serif',
    Merriweather: 'merriweather',
    Cinzel: 'cinzel',
    Lato: 'modern-sans',
    'Zilla Slab': 'zilla-slab',
    'Great Vibes': 'script',
    'Dancing Script': 'dancing',
    Caveat: 'handwritten',
    'Indie Flower': 'indie',
    'Special Elite': 'typewriter',
    Orbitron: 'futuristic',
    Rajdhani: 'tech',
  };

  var VALID_FONT_KEYS = {};
  [
    'classic-serif', 'merriweather', 'cinzel', 'modern-sans', 'zilla-slab', 'script', 'dancing',
    'handwritten', 'indie', 'typewriter', 'futuristic', 'tech',
    'jp-noto-serif', 'jp-noto-sans', 'jp-shippori', 'jp-klee', 'jp-yuji-syuku', 'jp-yuji-mai',
    'jp-yuji-boku', 'jp-hina', 'jp-zen-kurenaido', 'jp-yusei', 'jp-reggae',
  ].forEach(function (k) {
    VALID_FONT_KEYS[k] = 1;
  });

  window.normalizeFontKey = function (v) {
    if (v == null || v === '') return 'classic-serif';
    if (typeof v !== 'string') v = String(v);
    v = v.trim();
    if (!v) return 'classic-serif';
    if (LEGACY_FONT_MAP[v]) return LEGACY_FONT_MAP[v];
    if (v.length > 1 && v.charAt(0).toLowerCase() === 'f' && v.charAt(1) === '-') {
      v = v.slice(2);
    }
    if (VALID_FONT_KEYS[v]) return v;
    return 'classic-serif';
  };

  // フォントキー → CSS クラス切替（'classic-serif' / 'jp-yuji-mai' 等）。fontKey は normalizeFontKey 済みを渡す。
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
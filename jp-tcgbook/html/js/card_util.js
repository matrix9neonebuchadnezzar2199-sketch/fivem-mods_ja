/**
 * コレクション／デッキで共用するカード表示ヘルパ
 * グローバル: window.CardUtil
 */
(function (global) {
  const EMOJI_POOL = ['🐉', '🦅', '🛡', '⚔', '🔥', '❄', '⚡', '🌙', '⭐', '🎯', '🎴', '🌀'];

  function emojiFromId(cardId) {
    let h = 0;
    const s = String(cardId || '');
    for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0;
    return EMOJI_POOL[h % EMOJI_POOL.length];
  }

  function escapeHtmlAttr(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/"/g, '&quot;')
      .replace(/</g, '&lt;');
  }

  /** NUI は html/index.html 基準。assets/... または旧 html/assets/... に対応 */
  function resolveCardImageSrc(imagePath) {
    const p = String(imagePath || '').trim();
    if (!p || /^https?:\/\//i.test(p)) return p;
    let u = p.replace(/^html\//i, '');
    return u.replace(/^\//, '');
  }

  /** .card-art / .slot-art / .preview-art 内の中央イラスト（画像が無い・読込失敗時は絵文字） */
  function cardArtMediaHtml(cardId, imagePath) {
    const src = resolveCardImageSrc(imagePath);
    const emoji = emojiFromId(cardId);
    let inner = `<span class="card-art-fallback">${emoji}</span>`;
    if (src) {
      inner =
        `<img class="card-art-img" src="${escapeHtmlAttr(src)}" alt="" loading="lazy" decoding="async" onerror="this.remove();">` +
        inner;
    }
    return `<div class="card-art-media">${inner}</div>`;
  }

  /**
   * .mini-stat.s-top / .s-right / .s-bottom / .s-left を対象に .max を付与
   * @param {HTMLElement} cardEl
   * @param {{ stat_top: number, stat_right: number, stat_bottom: number, stat_left: number }} stats
   */
  function applyMaxHighlight(cardEl, stats) {
    const vals = [
      Number(stats.stat_top),
      Number(stats.stat_right),
      Number(stats.stat_bottom),
      Number(stats.stat_left),
    ];
    const mx = Math.max(vals[0], vals[1], vals[2], vals[3]);
    const cls = ['s-top', 's-right', 's-bottom', 's-left'];
    cls.forEach((c, i) => {
      const el = cardEl.querySelector('.mini-stat.' + c);
      if (!el) return;
      if (vals[i] === mx) el.classList.add('max');
      else el.classList.remove('max');
    });
  }

  /**
   * 詳細プレビュー用 .detail-stat-num.stat-*
   * @param {HTMLElement} root
   * @param {{ stat_top: number, stat_right: number, stat_bottom: number, stat_left: number }} stats
   */
  function applyMaxHighlightDetail(root, stats) {
    const vals = [
      Number(stats.stat_top),
      Number(stats.stat_right),
      Number(stats.stat_bottom),
      Number(stats.stat_left),
    ];
    const mx = Math.max(vals[0], vals[1], vals[2], vals[3]);
    const cls = ['stat-top', 'stat-right', 'stat-bottom', 'stat-left'];
    cls.forEach((c, i) => {
      const el = root.querySelector('.detail-stat-num.' + c);
      if (!el) return;
      if (vals[i] === mx) el.classList.add('max');
      else el.classList.remove('max');
    });
  }

  /**
   * @param {{ cardsMaster?: unknown[], cards?: unknown[] }} appState
   */
  function normalizeMasterList(appState) {
    const cm = appState && Array.isArray(appState.cardsMaster) ? appState.cardsMaster : [];
    if (cm.length > 0) return cm;

    const inst = (appState && Array.isArray(appState.cards)) ? appState.cards : [];
    const byId = new Map();
    inst.forEach((row) => {
      if (!row.card_id || byId.has(row.card_id)) return;
      byId.set(row.card_id, {
        card_id: row.card_id,
        name: row.name,
        rank: row.rank,
        type: row.type,
        stat_top: row.stat_top,
        stat_right: row.stat_right,
        stat_bottom: row.stat_bottom,
        stat_left: row.stat_left,
        image_path: row.image_path || '',
        description: row.description || '',
        no: row.no,
      });
    });
    return Array.from(byId.values());
  }

  /** @param {{ stat_top: number, stat_right: number, stat_bottom: number, stat_left: number }} c */
  function cardPower(c) {
    return Math.max(
      Number(c.stat_top),
      Number(c.stat_right),
      Number(c.stat_bottom),
      Number(c.stat_left),
    );
  }

  global.CardUtil = {
    emojiFromId,
    escapeHtmlAttr,
    resolveCardImageSrc,
    cardArtMediaHtml,
    applyMaxHighlight,
    applyMaxHighlightDetail,
    normalizeMasterList,
    cardPower,
  };
})(window);

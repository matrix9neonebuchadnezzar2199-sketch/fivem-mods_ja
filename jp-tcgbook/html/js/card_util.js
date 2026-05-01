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
    applyMaxHighlight,
    applyMaxHighlightDetail,
    normalizeMasterList,
    cardPower,
  };
})(window);

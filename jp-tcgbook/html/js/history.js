/**
 * 対戦履歴タブ（M3）
 */
(function (global) {
  function $(sel, root) {
    return (root || document).querySelector(sel);
  }

  function outcomeLabel(o) {
    const tr = global.I18n && global.I18n.t ? global.I18n.t.bind(global.I18n) : null;
    if (tr) {
      if (o === 'win') return tr('hist_outcome_win');
      if (o === 'lose') return tr('hist_outcome_lose');
      if (o === 'draw') return tr('hist_outcome_draw');
    } else {
      if (o === 'win') return '勝ち';
      if (o === 'lose') return '負け';
      if (o === 'draw') return '引分';
    }
    return o || '—';
  }

  function outcomeClass(o) {
    if (o === 'win') return 'hist-outcome-win';
    if (o === 'lose') return 'hist-outcome-lose';
    return 'hist-outcome-draw';
  }

  function fmtTime(epochSec) {
    const n = Number(epochSec);
    if (!Number.isFinite(n) || n <= 0) return '—';
    try {
      const loc = global.I18n && global.I18n.getLang && global.I18n.getLang() === 'en' ? 'en-US' : 'ja-JP';
      return new Date(n * 1000).toLocaleString(loc);
    } catch (_) {
      return String(epochSec);
    }
  }

  function fmtRating(before, after) {
    const b = Number(before);
    const a = Number(after);
    if (!Number.isFinite(b) || !Number.isFinite(a)) return '—';
    const d = a - b;
    if (d === 0) return `${a} (±0)`;
    const sign = d > 0 ? '+' : '';
    return `${a} (${sign}${d})`;
  }

  function render() {
    const tbody = $('#histTableBody');
    const emptyEl = $('#histEmpty');
    const countEl = $('#histCount');
    if (!tbody || !emptyEl) return;

    const rows = Array.isArray(global.AppState.matchHistory) ? global.AppState.matchHistory : [];
    if (countEl) countEl.textContent = String(rows.length);

    tbody.textContent = '';
    if (!rows.length) {
      emptyEl.hidden = false;
      return;
    }
    emptyEl.hidden = true;

    for (let i = 0; i < rows.length; i++) {
      const r = rows[i] || {};
      const tr = document.createElement('tr');

      const tdWhen = document.createElement('td');
      tdWhen.textContent = fmtTime(r.finished_at);

      const tdOpp = document.createElement('td');
      const oppName = r.opponent_display || '';
      const oppId = r.opponent_citizenid || '';
      tdOpp.textContent = oppName || oppId || '—';
      tdOpp.title = oppId || '';

      const tdRes = document.createElement('td');
      const sp = document.createElement('span');
      sp.textContent = outcomeLabel(r.outcome_me);
      sp.className = outcomeClass(r.outcome_me);
      tdRes.appendChild(sp);

      const tdScore = document.createElement('td');
      tdScore.textContent =
        r.score_me != null && r.score_opp != null ? `${r.score_me} – ${r.score_opp}` : '—';

      const tdRate = document.createElement('td');
      tdRate.textContent = fmtRating(r.rating_me_before, r.rating_me_after);

      const tdCopy = document.createElement('td');
      const tr = global.I18n && global.I18n.t ? global.I18n.t.bind(global.I18n) : null;
      if (r.defeat_copy_received && r.defeat_copy_card_id) {
        tdCopy.textContent = tr
          ? tr('hist_copy_prefix') + r.defeat_copy_card_id
          : `コピー: ${r.defeat_copy_card_id}`;
      } else if (r.defeat_copy_received) {
        tdCopy.textContent = tr ? tr('hist_copy_yes') : 'コピーあり';
      } else {
        tdCopy.textContent = '—';
      }

      tr.appendChild(tdWhen);
      tr.appendChild(tdOpp);
      tr.appendChild(tdRes);
      tr.appendChild(tdScore);
      tr.appendChild(tdRate);
      tr.appendChild(tdCopy);
      tbody.appendChild(tr);
    }
  }

  global.HistoryTab = { render };
})(window);

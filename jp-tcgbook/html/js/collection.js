/**
 * コレクションタブ（フィルタ・ソート・グリッド・詳細）
 * グローバル: window.Collection
 */
(function (global) {
  const RANK_ORDER = { UR: 6, SS: 5, S: 4, A: 3, B: 2, C: 1 };

  const CU = global.CardUtil;

  /** @type {{ filters: { search: string, type: string, rank: string }, sort: string, selectedCardId: string|null }} */
  const state = {
    filters: { search: '', type: 'all', rank: 'all' },
    sort: 'rank',
    selectedCardId: null,
  };

  let bound = false;

  function parseObtainedAt(s) {
    const t = Date.parse(String(s || '').replace(' ', 'T'));
    return Number.isFinite(t) ? t : 0;
  }

  /** @returns {Map<string, { count: number, latest: number }>} */
  function buildOwnership(instances) {
    const map = new Map();
    if (!Array.isArray(instances)) return map;
    instances.forEach((row) => {
      const id = row.card_id;
      if (!id) return;
      const ts = parseObtainedAt(row.obtained_at);
      const cur = map.get(id);
      if (!cur) map.set(id, { count: 1, latest: ts });
      else {
        cur.count += 1;
        cur.latest = Math.max(cur.latest, ts);
      }
    });
    return map;
  }

  function passesSearch(m, q) {
    if (!q) return true;
    const n = String(m.name || '').toLowerCase();
    const id = String(m.card_id || '').toLowerCase();
    return n.includes(q) || id.includes(q);
  }

  function passesType(m, t) {
    if (t === 'all') return true;
    if (t === 'free') return m.type === 'free';
    if (t === 'shitei') return m.type === 'shitei';
    return true;
  }

  function passesRank(m, r) {
    if (r === 'all') return true;
    return m.rank === r;
  }

  function rankSortValue(rank) {
    return RANK_ORDER[rank] || 0;
  }

  function sortRows(rows, sortKey) {
    const copy = rows.slice();
    if (sortKey === 'name') {
      copy.sort((a, b) =>
        String(a.master.name || '').localeCompare(String(b.master.name || ''), 'ja'),
      );
    } else if (sortKey === 'date') {
      copy.sort((a, b) => {
        const da = a.ownedCount > 0 ? a.latestMs : -1;
        const db = b.ownedCount > 0 ? b.latestMs : -1;
        if (da !== db) return db - da;
        return rankSortValue(b.master.rank) - rankSortValue(a.master.rank);
      });
    } else {
      copy.sort((a, b) => {
        const rd = rankSortValue(b.master.rank) - rankSortValue(a.master.rank);
        if (rd !== 0) return rd;
        return String(a.master.name || '').localeCompare(String(b.master.name || ''), 'ja');
      });
    }
    return copy;
  }

  /**
   * master + ownership → 行
   */
  function buildRows(masterList, ownershipMap) {
    return masterList.map((m) => {
      const o = ownershipMap.get(m.card_id);
      const ownedCount = o ? o.count : 0;
      const latestMs = o ? o.latest : 0;
      return {
        master: m,
        ownedCount,
        latestMs,
      };
    });
  }

  function filterRows(rows, filters) {
    const q = filters.search.trim().toLowerCase();
    return rows.filter((row) => {
      const m = row.master;
      return passesSearch(m, q) && passesType(m, filters.type) && passesRank(m, filters.rank);
    });
  }

  /** search のみ適用（種別カウント用ベース） */
  function applySearchOnly(masterList, ownershipMap, search) {
    const q = search.trim().toLowerCase();
    const rows = buildRows(masterList, ownershipMap);
    return rows.filter((row) => passesSearch(row.master, q));
  }

  function updateSidebarCounts(masterList, ownershipMap) {
    const base = applySearchOnly(masterList, ownershipMap, state.filters.search);

    const setCount = (sel, n) => {
      const el = document.querySelector(sel);
      if (el) el.textContent = String(n);
    };

    setCount('[data-col-count="type-all"]', base.length);
    setCount(
      '[data-col-count="type-free"]',
      base.filter((r) => r.master.type === 'free').length,
    );
    setCount(
      '[data-col-count="type-shitei"]',
      base.filter((r) => r.master.type === 'shitei').length,
    );

    let typeFiltered = base;
    if (state.filters.type === 'free') typeFiltered = base.filter((r) => r.master.type === 'free');
    else if (state.filters.type === 'shitei')
      typeFiltered = base.filter((r) => r.master.type === 'shitei');

    setCount('[data-col-count="rank-all"]', typeFiltered.length);
    ['UR', 'SS', 'S', 'A', 'B', 'C'].forEach((rk) => {
      setCount(
        `[data-col-count="rank-${rk}"]`,
        typeFiltered.filter((r) => r.master.rank === rk).length,
      );
    });
  }

  function updateCompletion(masterList, ownershipMap) {
    const total = masterList.length;
    const ownedUnique = masterList.filter((m) => (ownershipMap.get(m.card_id)?.count || 0) > 0)
      .length;
    const pct = total > 0 ? Math.round((ownedUnique / total) * 1000) / 10 : 0;

    const textEl = document.getElementById('colCompletionText');
    const barEl = document.getElementById('colCompletionBarFill');
    if (textEl) textEl.textContent = `${ownedUnique}/${total} (${pct}%)`;
    if (barEl) barEl.style.width = `${Math.min(100, pct)}%`;
  }

  function renderGrid(rows) {
    const grid = document.getElementById('colGrid');
    if (!grid) return;
    grid.innerHTML = '';

    const sorted = sortRows(rows, state.sort);

    sorted.forEach((row) => {
      const m = row.master;
      const card = document.createElement('div');
      card.className = 'card';
      card.dataset.cardId = m.card_id;
      if (row.ownedCount === 0) card.classList.add('unowned');
      if (state.selectedCardId === m.card_id) card.classList.add('selected');

      const typeEl = document.createElement('span');
      typeEl.className = 'card-type' + (m.type === 'shitei' ? ' shitei' : '');
      typeEl.textContent = m.type === 'shitei' ? '指定' : 'フリー';

      const rankEl = document.createElement('span');
      rankEl.className = 'card-rank rank-' + m.rank;
      rankEl.textContent = m.rank;

      const art = document.createElement('div');
      art.className = 'card-art';
      art.innerHTML =
        `<span class="mini-stat s-top">${m.stat_top}</span>` +
        `<span class="mini-stat s-right">${m.stat_right}</span>` +
        `<span class="mini-stat s-bottom">${m.stat_bottom}</span>` +
        `<span class="mini-stat s-left">${m.stat_left}</span>` +
        `<span>${CU.emojiFromId(m.card_id)}</span>`;

      CU.applyMaxHighlight(card, m);

      const nm = document.createElement('div');
      nm.className = 'card-name';
      nm.textContent = m.name || m.card_id;

      card.appendChild(typeEl);
      card.appendChild(rankEl);
      card.appendChild(art);
      card.appendChild(nm);

      if (row.ownedCount > 0) {
        const badge = document.createElement('span');
        badge.className = 'owned-badge';
        badge.textContent = `×${row.ownedCount}`;
        card.appendChild(badge);
      }

      card.addEventListener('click', () => {
        if (row.ownedCount === 0) return;
        if (state.selectedCardId === m.card_id) state.selectedCardId = null;
        else state.selectedCardId = m.card_id;
        Collection.render();
      });

      grid.appendChild(card);
    });
  }

  function renderDetail(rowOrNull) {
    const host = document.getElementById('colDetailBody');
    if (!host) return;
    host.innerHTML = '';

    if (!rowOrNull || rowOrNull.ownedCount === 0) {
      const empty = document.createElement('div');
      empty.className = 'detail-empty';
      empty.textContent = rowOrNull
        ? '未所持のカードです'
        : 'カードを選択すると詳細が表示されます';
      host.appendChild(empty);
      return;
    }

    const m = rowOrNull.master;

    const preview = document.createElement('div');
    preview.className = 'detail-card-preview';

    const pt = document.createElement('span');
    pt.className = 'preview-type' + (m.type === 'shitei' ? ' shitei' : '');
    pt.textContent = m.type === 'shitei' ? '指定' : 'フリー';

    const pr = document.createElement('span');
    pr.className = 'preview-rank rank-' + m.rank;
    pr.textContent = m.rank;

    const pa = document.createElement('div');
    pa.className = 'preview-art';
    pa.innerHTML =
      `<span class="detail-stat-num stat-top">${m.stat_top}</span>` +
      `<span class="detail-stat-num stat-right">${m.stat_right}</span>` +
      `<span class="detail-stat-num stat-bottom">${m.stat_bottom}</span>` +
      `<span class="detail-stat-num stat-left">${m.stat_left}</span>` +
        `<span>${CU.emojiFromId(m.card_id)}</span>`;

    CU.applyMaxHighlightDetail(pa, m);

    preview.appendChild(pt);
    preview.appendChild(pr);
    preview.appendChild(pa);

    const title = document.createElement('div');
    title.className = 'detail-name';
    title.textContent = m.name || '';

    const sub = document.createElement('div');
    sub.className = 'detail-sub';
    sub.textContent = `${m.card_id} ・ 所持 ${rowOrNull.ownedCount} 枚`;

    const desc = document.createElement('div');
    desc.className = 'detail-desc';
    desc.textContent = m.description || '—';

    const actions = document.createElement('div');
    actions.className = 'actions';

    [['デッキに追加', 'deck'], ['トレード申請', 'trade'], ['ベット', 'bet']].forEach(([label, key]) => {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'btn' + (key === 'deck' ? ' primary' : '');
      b.textContent = label;
      b.addEventListener('click', () => {
        console.debug('[jp-tcgbook collection]', key, m.card_id);
      });
      actions.appendChild(b);
    });

    host.appendChild(preview);
    host.appendChild(title);
    host.appendChild(sub);
    host.appendChild(desc);
    host.appendChild(actions);
  }

  function syncFilterUi() {
    document.querySelectorAll('[data-col-filter-type]').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.colFilterType === state.filters.type);
    });
    document.querySelectorAll('[data-col-filter-rank]').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.colFilterRank === state.filters.rank);
    });
    document.querySelectorAll('[data-col-sort]').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.colSort === state.sort);
    });

    const inp = document.getElementById('colSearch');
    if (inp && document.activeElement !== inp) inp.value = state.filters.search;
  }

  function bindDom() {
    if (bound) return;
    bound = true;

    const search = document.getElementById('colSearch');
    if (search) {
      search.addEventListener('input', () => {
        state.filters.search = search.value;
        Collection.render();
      });
    }

    document.querySelectorAll('[data-col-filter-type]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.filters.type = btn.dataset.colFilterType || 'all';
        Collection.render();
      });
    });

    document.querySelectorAll('[data-col-filter-rank]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.filters.rank = btn.dataset.colFilterRank || 'all';
        Collection.render();
      });
    });

    document.querySelectorAll('[data-col-sort]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.sort = btn.dataset.colSort || 'rank';
        Collection.render();
      });
    });
  }

  const Collection = {
    applyMaxHighlight: CU.applyMaxHighlight,
    /**
     * @param {{ filters?: Partial<typeof state.filters>, sort?: string, selectedCardId?: string|null }} [partial]
     */
    render(partial) {
      if (partial && typeof partial === 'object') {
        if (partial.filters && typeof partial.filters === 'object') {
          Object.assign(state.filters, partial.filters);
        }
        if (partial.sort) state.sort = partial.sort;
        if ('selectedCardId' in partial) state.selectedCardId = partial.selectedCardId;
      }
      bindDom();
      const masterList = CU.normalizeMasterList(global.AppState);
      const ownershipMap = buildOwnership(global.AppState.cards || []);
      const rowsAll = buildRows(masterList, ownershipMap);

      updateSidebarCounts(masterList, ownershipMap);
      updateCompletion(masterList, ownershipMap);

      const visible = filterRows(rowsAll, state.filters);
      syncFilterUi();
      renderGrid(visible);

      let selRow = null;
      if (state.selectedCardId) {
        selRow = visible.find((r) => r.master.card_id === state.selectedCardId) || null;
        if (!selRow) state.selectedCardId = null;
      }
      renderDetail(selRow);
    },
  };

  global.Collection = Collection;

  document.addEventListener('DOMContentLoaded', () => bindDom());
})(window);

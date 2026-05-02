/**
 * コレクションタブ（フィルタ・ソート・グリッド・詳細）
 * グローバル: window.Collection
 */
(function (global) {
  const RANK_ORDER = { UR: 6, SS: 5, S: 4, A: 3, B: 2, C: 1 };

  const CU = global.CardUtil;

  function tt(key, vars) {
    return global.I18n && global.I18n.tf ? global.I18n.tf(key, vars) : key;
  }

  function sortLocale() {
    return global.I18n && global.I18n.getLang && global.I18n.getLang() === 'en' ? 'en' : 'ja';
  }

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
        String(a.master.name || '').localeCompare(String(b.master.name || ''), sortLocale()),
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
        return String(a.master.name || '').localeCompare(String(b.master.name || ''), sortLocale());
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
      typeEl.textContent = m.type === 'shitei' ? tt('col_type_shitei') : tt('col_type_free');

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
        CU.cardArtMediaHtml(m.card_id, m.image_path);

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
      empty.textContent = rowOrNull ? tt('col_detail_not_owned') : tt('col_detail_pick_hint');
      host.appendChild(empty);
      return;
    }

    const m = rowOrNull.master;

    const preview = document.createElement('div');
    preview.className = 'detail-card-preview';

    const pt = document.createElement('span');
    pt.className = 'preview-type' + (m.type === 'shitei' ? ' shitei' : '');
    pt.textContent = m.type === 'shitei' ? tt('col_type_shitei') : tt('col_type_free');

    const pr = document.createElement('span');
    pr.className = 'preview-rank rank-' + m.rank;
    pr.textContent = m.rank;

    const pa = document.createElement('div');
    pa.className = 'preview-art';
    /* 詳細プレビューはイラスト優先のため四方向数値は出さない（グリッド側で表示） */
    pa.innerHTML = CU.cardArtMediaHtml(m.card_id, m.image_path);

    preview.appendChild(pt);
    preview.appendChild(pr);
    preview.appendChild(pa);

    const title = document.createElement('div');
    title.className = 'detail-name';
    title.textContent = m.name || '';

    const sub = document.createElement('div');
    sub.className = 'detail-sub';
    sub.textContent = tt('col_detail_owned_fmt', {
      id: m.card_id,
      count: rowOrNull.ownedCount,
    });

    const desc = document.createElement('div');
    desc.className = 'detail-desc';
    desc.textContent = CU.cardDescriptionForLocale(m) || '—';

    const actions = document.createElement('div');
    actions.className = 'actions';

    const deckBtn = document.createElement('button');
    deckBtn.type = 'button';
    deckBtn.className = 'btn primary';
    deckBtn.textContent = tt('col_btn_goto_deck');
    deckBtn.addEventListener('click', () => {
      if (typeof global.jpTcgbookSwitchTab === 'function') {
        global.jpTcgbookSwitchTab('deck');
      }
    });
    actions.appendChild(deckBtn);

    const note = document.createElement('div');
    note.className = 'detail-acquire-note';
    note.textContent = tt('col_acquire_hint');
    actions.appendChild(note);

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

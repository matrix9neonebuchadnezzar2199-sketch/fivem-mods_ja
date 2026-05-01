/**
 * デッキ編成タブ
 * グローバル: window.Deck
 */
(function (global) {
  const NUI = global.NUI;
  const api = global.api;
  const CU = global.CardUtil;

  const DECK_SIZE = 10;
  const MAX_DECKS = 10;
  const MAX_SHITEI = 2;
  const LIMIT_SHITEI_SAME = 1;
  const LIMIT_FREE_SAME = 2;

  /** @type {{ saveStatus: 'saved'|'saving'|'error', collectionFilters: {search:string,type:string,rank:string}, editingDeckId: number|null, renameBackup: string, renamePending: null|{deckId:number,backupName:string}, renameRevert: string|null, pendingSelectNewDeck: boolean, pendingSelectDupDeck: boolean }} */
  const state = {
    saveStatus: 'saved',
    collectionFilters: { search: '', type: 'all', rank: 'all' },
    editingDeckId: null,
    renameBackup: '',
    renamePending: null,
    renameRevert: null,
    pendingSelectNewDeck: false,
    pendingSelectDupDeck: false,
  };

  let bound = false;
  let nuiHooked = false;

  function hookNui() {
    if (nuiHooked) return;
    nuiHooked = true;

    NUI.on('deckUpdated', (payload) => {
      if (global.AppState.currentTab !== 'deck') return;
      state.saveStatus = payload && payload.success ? 'saved' : 'error';
      Deck.render();
    });

    NUI.on('deckListUpdated', (payload) => {
      if (!payload || !payload.success) {
        if (state.renamePending) {
          state.renameRevert = state.renamePending.backupName;
          state.editingDeckId = state.renamePending.deckId;
          state.renamePending = null;
        }
        if (global.AppState.currentTab === 'deck') Deck.render();
        return;
      }

      if (state.pendingSelectNewDeck && payload.data && payload.data.createdDeckId) {
        const nid = payload.data.createdDeckId;
        state.pendingSelectNewDeck = false;
        api.selectDeck(nid);
      } else if (state.pendingSelectDupDeck && payload.data && payload.data.createdDeckId) {
        const nid = payload.data.createdDeckId;
        state.pendingSelectDupDeck = false;
        api.selectDeck(nid);
      }
    });
  }

  function $(sel, root) {
    return (root || document).querySelector(sel);
  }

  function getSlot(slots, idx1) {
    if (!Array.isArray(slots)) return null;
    const found = slots.find((s) => Number(s.slot_index) === idx1);
    return found || slots[idx1 - 1] || null;
  }

  function countFilled(slots) {
    if (!Array.isArray(slots)) return 0;
    let n = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlot(slots, i);
      if (sl && sl.card) n++;
    }
    return n;
  }

  function countShiteiSlots(slots) {
    let n = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlot(slots, i);
      if (sl && sl.card && sl.card.type === 'shitei') n++;
    }
    return n;
  }

  function countInDeck(slots, cardId) {
    let n = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlot(slots, i);
      if (sl && sl.card && sl.card.card_id === cardId) n++;
    }
    return n;
  }

  function ownershipMap() {
    const m = new Map();
    (global.AppState.cards || []).forEach((row) => {
      const id = row.card_id;
      if (!id) return;
      m.set(id, (m.get(id) || 0) + 1);
    });
    return m;
  }

  function masterById() {
    const masters = CU.normalizeMasterList(global.AppState);
    const map = new Map();
    masters.forEach((c) => map.set(c.card_id, c));
    return map;
  }

  function passesCollSearch(m, q) {
    if (!q) return true;
    const n = String(m.name || '').toLowerCase();
    const id = String(m.card_id || '').toLowerCase();
    return n.includes(q) || id.includes(q);
  }

  function passesCollType(m, t) {
    if (t === 'all') return true;
    if (t === 'free') return m.type === 'free';
    if (t === 'shitei') return m.type === 'shitei';
    return true;
  }

  function passesCollRank(m, r) {
    if (r === 'all') return true;
    return m.rank === r;
  }

  function computeDeckStats(detail) {
    const slots = detail && detail.slots ? detail.slots : [];
    const filled = countFilled(slots);
    let totalPwr = 0;
    let maxStat = 0;
    const rankCounts = { UR: 0, SS: 0, S: 0, A: 0, B: 0, C: 0 };
    let shitei = 0;
    let free = 0;

    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlot(slots, i);
      if (!sl || !sl.card) continue;
      const c = sl.card;
      const p = CU.cardPower(c);
      totalPwr += p;
      ['stat_top', 'stat_right', 'stat_bottom', 'stat_left'].forEach((k) => {
        maxStat = Math.max(maxStat, Number(c[k]));
      });
      const rk = c.rank;
      if (rankCounts[rk] !== undefined) rankCounts[rk]++;
      if (c.type === 'shitei') shitei++;
      else free++;
    }

    const avg = filled > 0 ? Math.round((totalPwr / filled) * 10) / 10 : 0;

    return { filled, totalPwr, avg, maxStat, rankCounts, shitei, free };
  }

  function fisherYates(arr) {
    const a = arr.slice();
    for (let i = a.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const t = a[i];
      a[i] = a[j];
      a[j] = t;
    }
    return a;
  }

  function openModal(el) {
    if (!el) return;
    el.classList.add('is-open');
    el.setAttribute('aria-hidden', 'false');
  }

  function closeModal(el) {
    if (!el) return;
    el.classList.remove('is-open');
    el.setAttribute('aria-hidden', 'true');
  }

  function renderSidebar() {
    const list = $('#deckSidebarList');
    const badge = $('#deckCountBadge');
    const addBtn = $('#deckNewBtn');
    if (!list) return;

    const decks = global.AppState.decks || [];
    const curId = global.AppState.currentDeckId;
    const n = decks.length;
    const full = n >= MAX_DECKS;

    if (badge) {
      badge.innerHTML = `<span class="num">${n}</span> / ${MAX_DECKS}`;
      badge.classList.toggle('full', full);
    }
    if (addBtn) {
      addBtn.disabled = full;
      addBtn.classList.toggle('disabled', full);
    }

    list.innerHTML = '';

    decks.forEach((d) => {
      const item = document.createElement('div');
      item.className = 'deck-item';
      item.dataset.deckId = String(d.id);
      if (d.id === curId) item.classList.add('active');
      const filled = d.card_count != null ? d.card_count : 0;
      if (filled > 0 && filled < DECK_SIZE) item.classList.add('invalid');

      const activeMark =
        d.is_active === true || d.is_active === 1
          ? '<span class="deck-active-mark" aria-hidden="true">★</span>'
          : '';

      const power =
        d.power != null ? `PWR ${d.power}` : 'PWR —';

      if (state.editingDeckId === d.id) {
        const rev = state.renameRevert != null ? state.renameRevert : d.name;
        if (state.renameRevert != null) state.renameRevert = null;
        item.innerHTML =
          `${activeMark}<div class="deck-name-row">` +
          `<input type="text" class="deck-name-input-inline" maxlength="64" value="${escapeAttr(rev)}" aria-label="デッキ名"></div>` +
          `<div class="deck-item-info"><span>${filled}/${DECK_SIZE}</span><span class="deck-item-power">${power}</span></div>`;
        const inp = item.querySelector('.deck-name-input-inline');
        if (inp) {
          let blurTm = null;
          inp.addEventListener('click', (e) => e.stopPropagation());
          inp.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
              e.preventDefault();
              if (blurTm) clearTimeout(blurTm);
              submitRename(d.id, inp.value);
            } else if (e.key === 'Escape') {
              e.preventDefault();
              if (blurTm) clearTimeout(blurTm);
              state.editingDeckId = null;
              state.renamePending = null;
              Deck.render();
            }
          });
          inp.addEventListener('blur', () => {
            blurTm = setTimeout(() => {
              blurTm = null;
              if (state.editingDeckId !== d.id) return;
              submitRename(d.id, inp.value);
            }, 180);
          });
          inp.addEventListener('focus', () => {
            if (blurTm) clearTimeout(blurTm);
          });
          inp.focus();
          inp.select();
        }
      } else {
        item.innerHTML =
          `${activeMark}<div class="deck-name-row">` +
          `<span class="deck-item-name">${escapeHtml(d.name)}</span>` +
          `<button type="button" class="deck-edit-pencil" title="名前を編集" aria-label="名前を編集">✏</button></div>` +
          `<div class="deck-item-info"><span>${filled}/${DECK_SIZE}</span><span class="deck-item-power">${power}</span></div>`;

        const pencil = item.querySelector('.deck-edit-pencil');
        pencil?.addEventListener('click', (e) => {
          e.stopPropagation();
          state.editingDeckId = d.id;
          state.renameBackup = d.name;
          Deck.render();
        });
      }

      item.addEventListener('click', () => {
        if (state.editingDeckId === d.id) return;
        api.selectDeck(d.id);
      });

      list.appendChild(item);
    });
  }

  function escapeHtml(s) {
    return String(s || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function escapeAttr(s) {
    return escapeHtml(s).replace(/'/g, '&#39;');
  }

  function submitRename(deckId, raw) {
    const name = String(raw || '').trim();
    if (!name || name === state.renameBackup) {
      state.editingDeckId = null;
      state.renamePending = null;
      Deck.render();
      return;
    }
    state.renamePending = { deckId, backupName: state.renameBackup };
    state.editingDeckId = null;
    api.renameDeck(deckId, name);
    Deck.render();
  }

  function renderEditor(detail) {
    const nameEl = $('#deckNameDisplay');
    const saveEl = $('#deckSaveStatus');
    const filledEl = $('#deckCounterFilled');
    const shiteiEl = $('#deckCounterShitei');
    const grid = $('#deckSlotGrid');
    const statsEl = $('#deckStatsBar');
    const btnAct = $('#btnDeckActive');
    const btnCopy = $('#btnDeckCopy');
    const btnShuf = $('#btnDeckShuffle');
    const btnDel = $('#btnDeckDelete');

    const decks = global.AppState.decks || [];
    const deckCount = decks.length;
    const curId = global.AppState.currentDeckId;
    const fullDecks = deckCount >= MAX_DECKS;

    if (!detail || !curId) {
      if (nameEl) nameEl.textContent = 'デッキを選択してください';
      if (saveEl) {
        saveEl.className = 'save-status saved';
        saveEl.innerHTML = '<span class="save-dot"></span><span>—</span>';
      }
      if (grid) grid.innerHTML = '';
      if (statsEl) statsEl.innerHTML = '';
      if (btnAct) btnAct.disabled = true;
      if (btnCopy) btnCopy.disabled = fullDecks;
      if (btnDel) btnDel.disabled = true;
      return;
    }

    if (nameEl) nameEl.textContent = detail.name || '';

    if (saveEl) {
      const st = state.saveStatus;
      saveEl.className = 'save-status ' + st;
      const label = st === 'saved' ? '保存済み' : st === 'saving' ? '保存中…' : 'エラー';
      saveEl.innerHTML = `<span class="save-dot"></span><span>${label}</span>`;
    }

    const slots = detail.slots || [];
    const filled = countFilled(slots);
    const shiteiN = countShiteiSlots(slots);

    if (filledEl) {
      filledEl.innerHTML = `<span class="num">${filled}</span><span class="max"> / ${DECK_SIZE}</span> 枚`;
      filledEl.classList.toggle('full', filled >= DECK_SIZE);
    }
    if (shiteiEl) {
      shiteiEl.innerHTML = `指定 <span class="num" style="color:#ff4d4d">${shiteiN}</span><span class="max"> / ${MAX_SHITEI}</span>`;
    }

    if (grid) {
      grid.innerHTML = '';
      const deckId = detail.id;
      for (let i = 1; i <= DECK_SIZE; i++) {
        const sl = getSlot(slots, i);
        const cell = document.createElement('div');
        cell.className = 'deck-slot';
        cell.dataset.slot = String(i);

        if (!sl || !sl.card) {
          cell.textContent = '空き';
          grid.appendChild(cell);
          continue;
        }

        cell.classList.add('filled');
        const c = sl.card;

        const rm = document.createElement('button');
        rm.type = 'button';
        rm.className = 'slot-remove';
        rm.textContent = '×';
        rm.title = 'スロットから外す';
        rm.addEventListener('click', (e) => {
          e.stopPropagation();
          state.saveStatus = 'saving';
          Deck.render();
          api.removeDeckCard(deckId, i);
        });

        const tp = document.createElement('span');
        tp.className = 'slot-type' + (c.type === 'shitei' ? ' shitei' : '');
        tp.textContent = c.type === 'shitei' ? '指定' : 'フリー';

        const rk = document.createElement('span');
        rk.className = 'slot-rank rank-' + c.rank;
        rk.textContent = c.rank;

        const art = document.createElement('div');
        art.className = 'slot-art';
        art.innerHTML =
          `<span class="mini-stat s-top">${c.stat_top}</span>` +
          `<span class="mini-stat s-right">${c.stat_right}</span>` +
          `<span class="mini-stat s-bottom">${c.stat_bottom}</span>` +
          `<span class="mini-stat s-left">${c.stat_left}</span>` +
          CU.cardArtMediaHtml(c.card_id, c.image_path);
        CU.applyMaxHighlight(art, c);

        const nm = document.createElement('div');
        nm.className = 'slot-name';
        nm.textContent = c.name || c.card_id;

        const ix = document.createElement('span');
        ix.className = 'slot-index';
        ix.textContent = String(i);

        cell.appendChild(rm);
        cell.appendChild(tp);
        cell.appendChild(rk);
        cell.appendChild(art);
        cell.appendChild(nm);
        cell.appendChild(ix);
        grid.appendChild(cell);
      }
    }

    const st = computeDeckStats(detail);
    if (statsEl) {
      const parts = rankMiniSpans(st.rankCounts);
      statsEl.innerHTML =
        `<div class="stat-block"><div class="stat-value">${st.totalPwr}</div><div class="stat-label">総合PWR</div></div>` +
        `<div class="stat-block"><div class="stat-value">${st.avg}</div><div class="stat-label">平均PWR</div></div>` +
        `<div class="stat-block"><div class="stat-value">${st.maxStat}</div><div class="stat-label">最大ステ</div></div>` +
        `<div class="stat-block"><div class="stat-value" style="color:#ff4d4d">${st.shitei}/${st.free}</div><div class="stat-label">指定/フリー</div></div>` +
        `<div class="stat-block"><div class="stat-label" style="margin-top:0">ランク内訳</div><div class="rank-mini-bar">${parts}</div></div>`;
    }

    const lastDeck = deckCount <= 1;
    if (btnAct) btnAct.disabled = filled < DECK_SIZE;
    if (btnCopy) btnCopy.disabled = fullDecks;
    if (btnDel) btnDel.disabled = lastDeck;
    if (btnShuf) btnShuf.disabled = filled < 1;
  }

  function rankMiniSpans(rankCounts) {
    const order = ['UR', 'SS', 'S', 'A', 'B', 'C'];
    let html = '';
    order.forEach((rk) => {
      const n = rankCounts[rk] || 0;
      if (n <= 0) return;
      let cls = 'rank-' + rk;
      let style = '';
      if (rk === 'UR')
        style = 'background:linear-gradient(135deg,#ff00aa,#ff4d4d);color:#fff';
      else if (rk === 'SS')
        style = 'background:linear-gradient(135deg,#cc66ff,#8844ff);color:#fff';
      else if (rk === 'S') style = 'background:#ff9933';
      else if (rk === 'A') style = 'background:#ffd633';
      else if (rk === 'B') style = 'background:#99ccff';
      else style = 'background:#aaaaaa';
      html += `<span class="${cls}" style="${style}">${rk}${n}</span>`;
    });
    return html || '<span style="font-size:9px;color:#8b7d4a">—</span>';
  }

  function renderCollectionPane(detail) {
    const grid = $('#deckCollGrid');
    const searchEl = $('#deckCollSearch');
    const ownEl = $('#deckCollOwnedCount');
    if (!grid) return;

    if (!detail || !detail.id) {
      grid.innerHTML = '';
      if (ownEl) ownEl.textContent = '—';
      return;
    }

    const masters = CU.normalizeMasterList(global.AppState);
    const own = ownershipMap();
    const slots = detail && detail.slots ? detail.slots : [];
    const filled = countFilled(slots);
    const shiteiSlots = countShiteiSlots(slots);
    const deckFull = filled >= DECK_SIZE;

    if (ownEl) ownEl.textContent = `${global.AppState.cards?.length || 0}枚`;

    const q = state.collectionFilters.search.trim().toLowerCase();
    const filtered = masters.filter(
      (m) =>
        passesCollSearch(m, q) &&
        passesCollType(m, state.collectionFilters.type) &&
        passesCollRank(m, state.collectionFilters.rank),
    );

    grid.innerHTML = '';

    filtered.forEach((m) => {
      const owned = own.get(m.card_id) || 0;
      const inDeck = countInDeck(slots, m.card_id);
      const remainInv = Math.max(0, owned - inDeck);
      const limitSame = m.type === 'shitei' ? LIMIT_SHITEI_SAME : LIMIT_FREE_SAME;
      const roomSame = Math.max(0, limitSame - inDeck);
      const canAddSame = deckFull ? 0 : Math.min(remainInv, roomSame);

      const exhausted = remainInv <= 0 || canAddSame <= 0;
      const disabledShitei =
        m.type === 'shitei' && shiteiSlots >= MAX_SHITEI && inDeck === 0;

      const card = document.createElement('div');
      card.className = 'mini-card';
      if (exhausted) card.classList.add('exhausted');
      if (disabledShitei) card.classList.add('disabled-shitei');
      if (deckFull) card.classList.add('deck-full');

      const tp = document.createElement('span');
      tp.className = 'slot-type' + (m.type === 'shitei' ? ' shitei' : '');
      tp.textContent = m.type === 'shitei' ? '指定' : 'フリー';

      const rk = document.createElement('span');
      rk.className = 'slot-rank rank-' + m.rank;
      rk.textContent = m.rank;

      const art = document.createElement('div');
      art.className = 'slot-art';
      art.innerHTML =
        `<span class="mini-stat s-top">${m.stat_top}</span>` +
        `<span class="mini-stat s-right">${m.stat_right}</span>` +
        `<span class="mini-stat s-bottom">${m.stat_bottom}</span>` +
        `<span class="mini-stat s-left">${m.stat_left}</span>` +
        CU.cardArtMediaHtml(m.card_id, m.image_path);
      CU.applyMaxHighlight(art, m);

      const nm = document.createElement('div');
      nm.className = 'slot-name';
      nm.textContent = m.name || m.card_id;

      const badge = document.createElement('span');
      badge.className = 'remain-badge';
      if (remainInv <= 0) {
        badge.classList.add('zero');
        badge.textContent = '残0';
      } else {
        badge.classList.add(m.type === 'shitei' ? 'shitei' : 'free');
        badge.textContent = `残${remainInv}`;
      }

      const addBtn = document.createElement('button');
      addBtn.type = 'button';
      addBtn.className = 'add-btn';
      addBtn.textContent = '+';
      addBtn.disabled = exhausted || disabledShitei || deckFull || !detail;
      addBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        if (!detail || addBtn.disabled) return;
        state.saveStatus = 'saving';
        Deck.render();
        api.addCardToDeck(detail.id, m.card_id);
      });

      card.appendChild(tp);
      card.appendChild(rk);
      card.appendChild(art);
      card.appendChild(nm);
      card.appendChild(badge);
      card.appendChild(addBtn);
      grid.appendChild(card);
    });

    if (searchEl && document.activeElement !== searchEl) {
      searchEl.value = state.collectionFilters.search;
    }

    document.querySelectorAll('[data-deck-chip-type]').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.deckChipType === state.collectionFilters.type);
    });
    document.querySelectorAll('[data-deck-chip-rank]').forEach((btn) => {
      btn.classList.toggle(
        'active',
        btn.dataset.deckChipRank === state.collectionFilters.rank,
      );
    });
  }

  function bindDom() {
    if (bound) return;
    bound = true;
    hookNui();

    $('#deckNewBtn')?.addEventListener('click', () => {
      const decks = global.AppState.decks || [];
      if (decks.length >= MAX_DECKS) return;
      let base = '新規デッキ';
      const names = new Set(decks.map((d) => d.name));
      let name = base;
      let i = 2;
      while (names.has(name)) {
        name = `${base} ${i}`;
        i++;
      }
      state.pendingSelectNewDeck = true;
      api.createDeck(name);
    });

    $('#deckCollSearch')?.addEventListener('input', (e) => {
      const t = e.target;
      state.collectionFilters.search = t && 'value' in t ? t.value : '';
      Deck.render();
    });

    document.querySelectorAll('[data-deck-chip-type]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.collectionFilters.type = btn.dataset.deckChipType || 'all';
        Deck.render();
      });
    });

    document.querySelectorAll('[data-deck-chip-rank]').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.collectionFilters.rank = btn.dataset.deckChipRank || 'all';
        Deck.render();
      });
    });

    $('#deckHelpOpenBtn')?.addEventListener('click', () => openModal($('#deckHelpModal')));
    $('#deckHelpCloseBtn')?.addEventListener('click', () => closeModal($('#deckHelpModal')));
    $('#deckHelpModal')?.addEventListener('click', (e) => {
      if (e.target.id === 'deckHelpModal') closeModal($('#deckHelpModal'));
    });

    $('#deckShuffleCloseBtn')?.addEventListener('click', () =>
      closeModal($('#deckShuffleModal')),
    );
    $('#deckShuffleModal')?.addEventListener('click', (e) => {
      if (e.target.id === 'deckShuffleModal') closeModal($('#deckShuffleModal'));
    });

    $('#deckDeleteCloseBtn')?.addEventListener('click', () =>
      closeModal($('#deckDeleteModal')),
    );
    $('#deckDeleteCancelBtn')?.addEventListener('click', () =>
      closeModal($('#deckDeleteModal')),
    );
    $('#deckDeleteModal')?.addEventListener('click', (e) => {
      if (e.target.id === 'deckDeleteModal') closeModal($('#deckDeleteModal'));
    });

    $('#btnDeckActive')?.addEventListener('click', () => {
      const d = global.AppState.currentDeckDetail;
      if (!d || countFilled(d.slots) < DECK_SIZE) return;
      api.setActiveDeck(d.id);
    });

    $('#btnDeckCopy')?.addEventListener('click', () => {
      const d = global.AppState.currentDeckDetail;
      const decks = global.AppState.decks || [];
      if (!d || decks.length >= MAX_DECKS) return;
      state.pendingSelectDupDeck = true;
      api.duplicateDeck(d.id);
    });

    $('#btnDeckShuffle')?.addEventListener('click', () => {
      const d = global.AppState.currentDeckDetail;
      if (!d || !d.slots) return;
      const names = [];
      for (let i = 1; i <= DECK_SIZE; i++) {
        const sl = getSlot(d.slots, i);
        if (sl && sl.card) names.push(sl.card.name || sl.card.card_id);
      }
      if (!names.length) return;
      const shuffled = fisherYates(names);
      const top5 = shuffled.slice(0, 5);
      const prev = $('#deckShufflePreview');
      if (prev) {
        prev.innerHTML = top5
          .map((n) => `<div class="shuffle-chip">${escapeHtml(n)}</div>`)
          .join('');
      }
      openModal($('#deckShuffleModal'));
    });

    $('#btnDeckDelete')?.addEventListener('click', () => {
      const d = global.AppState.currentDeckDetail;
      const decks = global.AppState.decks || [];
      if (!d || decks.length <= 1) return;
      openModal($('#deckDeleteModal'));
    });

    $('#deckDeleteConfirmBtn')?.addEventListener('click', () => {
      const d = global.AppState.currentDeckDetail;
      closeModal($('#deckDeleteModal'));
      if (d) api.deleteDeck(d.id);
    });
  }

  const Deck = {
    render(partial) {
      if (partial && typeof partial === 'object') {
        if (partial.collectionFilters && typeof partial.collectionFilters === 'object') {
          Object.assign(state.collectionFilters, partial.collectionFilters);
        }
        if (partial.saveStatus) state.saveStatus = partial.saveStatus;
      }
      bindDom();
      const detail = global.AppState.currentDeckDetail;
      renderSidebar();
      renderEditor(detail);
      renderCollectionPane(detail);
    },

    closeDeckModals() {
      closeModal($('#deckHelpModal'));
      closeModal($('#deckShuffleModal'));
      closeModal($('#deckDeleteModal'));
    },

    anyDeckModalOpen() {
      return ['deckHelpModal', 'deckShuffleModal', 'deckDeleteModal'].some((id) => {
        const el = document.getElementById(id);
        return el && el.classList.contains('is-open');
      });
    },
  };

  global.Deck = Deck;
})(window);

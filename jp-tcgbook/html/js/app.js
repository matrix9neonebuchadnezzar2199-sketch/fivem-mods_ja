/**
 * BOOK UI エントリ（タブ・モーダル・状態・NUI リスナー）
 */
(function (global) {
  const NUI = global.NUI;
  const api = global.api;

  global.AppState = {
    player: null,
    cards: [],
    cardsMaster: [],
    decks: [],
    activeDeckId: null,
    activeDeck: null,
    currentTab: 'collection',
    currentDeckId: null,
    selectedDeckDetail: null,
  };

  const TAB_ORDER = ['collection', 'deck', 'battle', 'trade', 'ranking'];

  let helpOpen = false;

  function $(sel) {
    return document.querySelector(sel);
  }

  function showError(message) {
    const t = document.getElementById('toast');
    if (!t) return;
    t.textContent = message || 'エラーが発生しました';
    t.hidden = false;
    clearTimeout(showError._tm);
    showError._tm = setTimeout(() => {
      t.hidden = true;
    }, 4500);
  }

  function renderHeader() {
    const p = global.AppState.player;
    const nameEl = $('#playerInfo .name');
    const statsEl = $('#playerInfo .stats');
    if (!nameEl || !statsEl) return;

    if (!p) {
      nameEl.textContent = '—';
      statsEl.textContent = '所持: — ・ レート —';
      return;
    }

    const cid = p.citizenid || '';
    nameEl.textContent =
      cid.length > 20 ? `${cid.slice(0, 18)}…` : cid || 'プレイヤー';

    const n = global.AppState.cards.length;
    const r = p.rating ?? '—';
    const w = p.wins ?? 0;
    const l = p.losses ?? 0;
    statsEl.textContent = `所持: ${n} 枚 ・ レート ${r} ・ ${w}勝 ${l}敗`;
  }

  function renderCollectionIfNeeded() {
    if (global.AppState.currentTab !== 'collection') return;
    if (typeof global.Collection !== 'undefined' && global.Collection.render) {
      global.Collection.render();
    }
  }

  function renderCurrentTab() {
    const tab = global.AppState.currentTab;
    if (tab === 'collection') {
      renderCollectionIfNeeded();
    } else if (tab === 'deck') {
      console.log('[jp-tcgbook] tab=deck selectedDeck=', global.AppState.selectedDeckDetail);
    } else {
      console.log('[jp-tcgbook] tab=', tab);
    }
  }

  function switchTab(tabName) {
    global.AppState.currentTab = tabName;

    document.querySelectorAll('.tabs .tab').forEach((btn) => {
      const on = btn.dataset.tab === tabName;
      btn.classList.toggle('active', on);
      btn.setAttribute('aria-selected', on ? 'true' : 'false');
    });

    document.querySelectorAll('.tab-content').forEach((sec) => {
      sec.classList.toggle('active', sec.dataset.tabPanel === tabName);
    });

    renderCurrentTab();
  }

  function openHelp() {
    const modal = $('#helpModal');
    if (!modal) return;
    helpOpen = true;
    modal.classList.add('is-open');
    modal.setAttribute('aria-hidden', 'false');
  }

  function closeHelp() {
    const modal = $('#helpModal');
    if (!modal) return;
    helpOpen = false;
    modal.classList.remove('is-open');
    modal.setAttribute('aria-hidden', 'true');
  }

  function bindTabs() {
    document.querySelectorAll('.tabs .tab').forEach((btn) => {
      btn.addEventListener('click', () => {
        const tab = btn.dataset.tab;
        if (tab) switchTab(tab);
      });
    });
  }

  function bindHelp() {
    $('#helpOpenBtn')?.addEventListener('click', () => openHelp());
    $('#helpCloseBtn')?.addEventListener('click', () => closeHelp());
    $('#helpModal')?.addEventListener('click', (e) => {
      if (e.target.id === 'helpModal') closeHelp();
    });
  }

  function bindKeyboard() {
    document.addEventListener('keydown', (e) => {
      const appEl = $('#app');
      if (!appEl || appEl.hidden) return;

      if (e.key === 'Tab' && !helpOpen) {
        e.preventDefault();
        const i = TAB_ORDER.indexOf(global.AppState.currentTab);
        const next = TAB_ORDER[(i + 1 + TAB_ORDER.length) % TAB_ORDER.length];
        switchTab(next);
        return;
      }

      if (e.key !== 'Escape') return;

      if (helpOpen) {
        e.preventDefault();
        closeHelp();
        return;
      }

      e.preventDefault();
      api.closeBook();
      appEl.hidden = true;
    });
  }

  /* --- NUI メッセージ（方式B） --- */

  NUI.on('open', () => {
    const appEl = $('#app');
    if (appEl) appEl.hidden = false;
  });

  NUI.on('bookData', (payload) => {
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : 'データ取得に失敗しました');
      return;
    }
    const d = payload.data || {};
    global.AppState.player = d.player || null;
    global.AppState.cards = Array.isArray(d.cards) ? d.cards : [];
    global.AppState.cardsMaster = Array.isArray(d.cardsMaster) ? d.cardsMaster : [];
    global.AppState.decks = Array.isArray(d.decks) ? d.decks : [];

    const active = global.AppState.decks.find((x) => x.is_active === true || x.is_active === 1);
    global.AppState.activeDeckId = active ? active.id : null;
    global.AppState.activeDeck = null;

    renderHeader();
    renderCurrentTab();
  });

  NUI.on('deckSelected', (payload) => {
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : 'デッキ取得に失敗しました');
      return;
    }
    global.AppState.selectedDeckDetail = payload.data || null;
    global.AppState.currentDeckId = payload.data ? payload.data.id : null;
    renderCurrentTab();
  });

  NUI.on('deckUpdated', (payload) => {
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : 'デッキ更新に失敗しました');
      return;
    }
    global.AppState.selectedDeckDetail = payload.data || null;
    renderCurrentTab();
  });

  NUI.on('deckListUpdated', (payload) => {
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : '一覧の更新に失敗しました');
      return;
    }
    const d = payload.data || {};
    global.AppState.decks = Array.isArray(d.decks) ? d.decks : [];
    global.AppState.cards = Array.isArray(d.cards) ? d.cards : [];
    if (Array.isArray(d.cardsMaster)) global.AppState.cardsMaster = d.cardsMaster;
    global.AppState.activeDeck = d.activeDeck || null;

    const active = global.AppState.decks.find((x) => x.is_active === true || x.is_active === 1);
    global.AppState.activeDeckId = active ? active.id : null;

    renderHeader();
    renderCurrentTab();
  });

  document.addEventListener('DOMContentLoaded', () => {
    bindTabs();
    bindHelp();
    bindKeyboard();

    if (!NUI.IS_FIVEM) {
      const appEl = $('#app');
      if (appEl) appEl.hidden = false;
      api.openBook();
    }
  });
})(window);

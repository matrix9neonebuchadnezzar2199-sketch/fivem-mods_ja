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
    /** GetDeck / selectDeck / deckUpdated の詳細 */
    currentDeckDetail: null,
    /** openBook の ui ブロック（デバウンス・サーバーID 等） */
    ui: { autoSaveDebounceMs: 500, playerServerId: null, allow_debug_battle: false },
    /** 仮想対戦ロビー（サーバー同期） */
    battleVirtual: {
      waiting: false,
      connectedPeerId: null,
      isCaller: null,
      lastError: null,
      /** サーバ battleSoloVirtualWireTest: 2人目クライアントなしの接続デモ */
      soloWireTest: false,
      soloPeerLabel: '',
      /** PvP 開始直後〜battlePvpStarted までの短い移行表示（任意） */
      matchPrepLabel: '',
    },
    /** アリーナ表示用。mode:'cpu' は battle_debug、mode:'pvp' は battle_pvp */
    battle: null,
    /** CPU 戦ロビー UI のみ（対局中は battle に状態がある） */
    battleCpuLobby: {
      debugLobbyOpen: false,
      lookupLabel: '',
    },
    /** openBook で受け取る対戦履歴（正規化済み） */
    matchHistory: [],
  };

  const TAB_ORDER = ['collection', 'deck', 'battle', 'history', 'ranking'];

  let helpOpen = false;

  /** @type {null | (() => void)} */
  let tcgConfirmAbort = null;

  function isCpuDuelActive() {
    const b = global.AppState.battle;
    return !!(b && b.mode === 'cpu');
  }

  function isPvpDuelActive() {
    const b = global.AppState.battle;
    return !!(b && b.mode === 'pvp');
  }

  /** CPU / PvP いずれかのアリーナ表示中（タブ移動・ESC の判定） */
  function isBattleArenaActive() {
    return isCpuDuelActive() || isPvpDuelActive();
  }

  /**
   * FiveM NUI では window.confirm が表示されずメインスレッドだけブロックすることがあるため、BOOK 内モーダルのみ使用する。
   * @param {string} message
   * @returns {Promise<boolean>}
   */
  function openTcgConfirm(message) {
    return new Promise((resolve) => {
      const modal = $('#tcgConfirmModal');
      const msgEl = $('#tcgConfirmMessage');
      const okBtn = $('#tcgConfirmOk');
      const cancelBtn = $('#tcgConfirmCancel');
      if (!modal || !msgEl || !okBtn || !cancelBtn) {
        resolve(true);
        return;
      }

      function finish(val) {
        tcgConfirmAbort = null;
        okBtn.removeEventListener('click', onOk);
        cancelBtn.removeEventListener('click', onCancel);
        modal.removeEventListener('click', onBackdrop);
        modal.classList.remove('is-open');
        modal.setAttribute('aria-hidden', 'true');
        resolve(val);
      }

      function onOk() {
        finish(true);
      }
      function onCancel() {
        finish(false);
      }
      function onBackdrop(ev) {
        if (ev.target === modal) onCancel();
      }

      tcgConfirmAbort = onCancel;
      msgEl.textContent = message;
      modal.classList.add('is-open');
      modal.setAttribute('aria-hidden', 'false');
      okBtn.addEventListener('click', onOk);
      cancelBtn.addEventListener('click', onCancel);
      modal.addEventListener('click', onBackdrop);
    });
  }

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
    /* ライセンス全文を表示（長い場合は CSS で折り返し） */
    nameEl.textContent = cid || 'プレイヤー';

    const n = global.AppState.cards.length;
    const r = p.rating ?? '—';
    const w = p.wins ?? 0;
    const l = p.losses ?? 0;
    const lv = p.pvp_level != null ? p.pvp_level : '—';
    const xp = p.pvp_exp != null ? p.pvp_exp : '—';
    const st = p.pvp_win_streak != null ? p.pvp_win_streak : '—';
    statsEl.textContent = `所持: ${n} 枚 ・ Lv ${lv}（EXP ${xp}）・ 連勝 ${st} ・ レート ${r} ・ ${w}勝 ${l}敗`;
  }

  function renderCollectionIfNeeded() {
    if (global.AppState.currentTab !== 'collection') return;
    if (typeof global.Collection !== 'undefined' && global.Collection.render) {
      global.Collection.render();
    }
  }

  function renderDeckIfNeeded() {
    if (global.AppState.currentTab !== 'deck') return;
    if (typeof global.Deck !== 'undefined' && global.Deck.render) {
      global.Deck.render();
    }
  }

  /** デッキタブ表示時: 現在IDが無効なら active または先頭を読み込み */
  function ensureDeckSelection() {
    const decks = global.AppState.decks || [];
    if (!decks.length) return;
    const cur = global.AppState.currentDeckId;
    if (cur && decks.some((d) => d.id === cur)) {
      if (!global.AppState.currentDeckDetail) {
        api.selectDeck(cur);
      }
      return;
    }
    const pick = global.AppState.activeDeckId || decks[0].id;
    api.selectDeck(pick);
  }

  function renderCurrentTab() {
    const tab = global.AppState.currentTab;
    if (tab === 'collection') {
      renderCollectionIfNeeded();
    } else if (tab === 'deck') {
      renderDeckIfNeeded();
    } else if (tab === 'battle') {
      /* Battle.render は下で常に呼ぶ（CPU 対戦中は他タブ表示でもアリーナ更新のため） */
    } else if (tab === 'history') {
      if (typeof global.HistoryTab !== 'undefined' && global.HistoryTab.render) {
        global.HistoryTab.render();
      }
    } else {
      console.log('[jp-tcgbook] tab=', tab);
    }
    if (typeof global.Battle !== 'undefined' && global.Battle.render) {
      global.Battle.render();
    }
  }

  function switchTab(tabName) {
    if (tabName !== global.AppState.currentTab && isBattleArenaActive()) {
      showError('対戦中は他のタブに切り替えられません。全画面の「対戦終了」で抜けてください。');
      return;
    }

    global.AppState.currentTab = tabName;

    document.querySelectorAll('.tabs .tab').forEach((btn) => {
      const on = btn.dataset.tab === tabName;
      btn.classList.toggle('active', on);
      btn.setAttribute('aria-selected', on ? 'true' : 'false');
    });

    document.querySelectorAll('.tab-content').forEach((sec) => {
      sec.classList.toggle('active', sec.dataset.tabPanel === tabName);
    });

    if (tabName === 'deck') {
      ensureDeckSelection();
    }

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

      const confirmModal = $('#tcgConfirmModal');
      if (confirmModal && confirmModal.classList.contains('is-open')) {
        if (e.key === 'Escape') {
          e.preventDefault();
          if (typeof tcgConfirmAbort === 'function') tcgConfirmAbort();
        }
        return;
      }

      if (e.key === 'Tab' && !helpOpen) {
        if (isBattleArenaActive()) {
          e.preventDefault();
          return;
        }
        e.preventDefault();
        const i = TAB_ORDER.indexOf(global.AppState.currentTab);
        const next = TAB_ORDER[(i + 1 + TAB_ORDER.length) % TAB_ORDER.length];
        switchTab(next);
        return;
      }

      if (e.key !== 'Escape') return;

      if (global.Deck && typeof global.Deck.anyDeckModalOpen === 'function' && global.Deck.anyDeckModalOpen()) {
        e.preventDefault();
        global.Deck.closeDeckModals();
        return;
      }

      if (helpOpen) {
        e.preventDefault();
        closeHelp();
        return;
      }

      const bvEsc = global.AppState.battleVirtual;
      const peer = bvEsc && bvEsc.connectedPeerId;
      const needBattleConfirm =
        peer != null || !!(bvEsc && bvEsc.soloWireTest) || isBattleArenaActive();
      if (needBattleConfirm) {
        e.preventDefault();
        void (async () => {
          const soloOnly =
            !!(bvEsc && bvEsc.soloWireTest) && peer == null && !isBattleArenaActive();
          const ok = await openTcgConfirm(
            soloOnly
              ? 'BOOK を閉じますか？\n\nソロ検証の仮想接続を終了します。'
              : 'BOOK を閉じますか？\n\n仮想対戦の接続中、または対戦アリーナ進行中です。続行すると終了し、接続中なら相手側も切断されます。',
          );
          if (!ok) return;
          api.closeBook();
          appEl.hidden = true;
        })();
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

  NUI.on('forceClose', () => {
    global.__tcgWireLog = false;
    const appEl = $('#app');
    if (appEl) appEl.hidden = true;
  });

  NUI.on('battleWaitingAck', (p) => {
    global.AppState.battleVirtual.waiting = !!(p && p.waiting);
    renderCurrentTab();
  });

  NUI.on('virtualBattleMatched', (p) => {
    global.AppState.battleVirtual.matchPrepLabel = '';
    if (p && p.is_cpu === true) {
      global.AppState.battleVirtual.connectedPeerId = null;
      global.AppState.battleVirtual.isCaller = null;
      global.AppState.battleVirtual.waiting = false;
      global.AppState.battleVirtual.soloWireTest = false;
      global.AppState.battleVirtual.soloPeerLabel = '';
      renderCurrentTab();
      return;
    }
    global.AppState.battleVirtual.soloWireTest = !!(p && p.solo_wire_test);
    global.AppState.battleVirtual.soloPeerLabel =
      p && typeof p.peer_label === 'string' ? p.peer_label : '';
    global.AppState.battleVirtual.connectedPeerId =
      p && p.peer_server_id != null ? Number(p.peer_server_id) : null;
    if (p && p.is_caller === true) {
      global.AppState.battleVirtual.isCaller = true;
    } else if (p && p.is_caller === false) {
      global.AppState.battleVirtual.isCaller = false;
    } else {
      global.AppState.battleVirtual.isCaller = null;
    }
    global.AppState.battleVirtual.waiting = false;
    if (p && p.is_pvp === true && global.AppState.battleVirtual.connectedPeerId != null) {
      global.AppState.battleVirtual.matchPrepLabel = '対戦準備中…';
    }
    renderCurrentTab();
  });

  NUI.on('virtualBattleEnded', () => {
    global.AppState.battleVirtual.connectedPeerId = null;
    global.AppState.battleVirtual.isCaller = null;
    global.AppState.battleVirtual.waiting = false;
    global.AppState.battleVirtual.soloWireTest = false;
    global.AppState.battleVirtual.soloPeerLabel = '';
    global.AppState.battleVirtual.matchPrepLabel = '';
    renderCurrentTab();
  });

  NUI.on('battleLobbyError', (p) => {
    showError(p && p.error ? p.error : 'エラー');
    renderCurrentTab();
  });

  NUI.on('battleDebugState', (p) => {
    global.AppState.battle = { mode: 'cpu', ...(p || {}) };
    renderCurrentTab();
  });

  NUI.on('battleDebugLookupAck', (p) => {
    global.AppState.battleCpuLobby = global.AppState.battleCpuLobby || {};
    if (p && p.ok === true) {
      global.AppState.battleCpuLobby.lookupLabel = p.display_name || '応答OK';
    } else {
      global.AppState.battleCpuLobby.lookupLabel = '';
      showError(p && p.error ? p.error : '検索に失敗しました');
    }
    renderCurrentTab();
  });

  NUI.on('battleDebugEnded', () => {
    const b = global.AppState.battle;
    if (b && b.mode === 'cpu') {
      global.AppState.battle = null;
    }
    renderCurrentTab();
  });

  const PVP_ERROR_REASON_JA = {
    session_not_found: '対戦セッションが見つかりません',
    not_in_session: 'この対戦の参加者ではありません',
    not_your_turn: '自分のターンではありません',
    turn_no_mismatch: '手番情報が古いです（画面を更新してください）',
    invalid_cell: 'マス指定が不正です',
    cell_occupied: 'そのマスは既に埋まっています',
    invalid_hand_index: '手札の指定が不正です',
    hand_card_missing: 'その手札はありません',
  };

  NUI.on('battlePvpStarted', (p) => {
    global.AppState.battleVirtual.matchPrepLabel = '';
    const x = p || {};
    global.AppState.battle = {
      mode: 'pvp',
      session_id: x.session_id,
      turn_no: x.turn_no,
      turn_server_id: x.turn_server_id,
      is_my_turn: !!x.is_my_turn,
      board: Array.isArray(x.board) ? x.board : [],
      my_hand: Array.isArray(x.my_hand) ? x.my_hand : [],
      opponent_hand_count: x.opponent_hand_count != null ? Number(x.opponent_hand_count) : 0,
      opponent_server_id: x.opponent_server_id,
      last_action: null,
      ended: false,
      result: null,
    };
    renderCurrentTab();
  });

  NUI.on('battlePvpState', (p) => {
    global.AppState.battleVirtual.matchPrepLabel = '';
    const x = p || {};
    const cur = global.AppState.battle;
    if (!cur || cur.mode !== 'pvp') {
      global.AppState.battle = {
        mode: 'pvp',
        session_id: x.session_id,
        turn_no: x.turn_no,
        turn_server_id: x.turn_server_id,
        is_my_turn: !!x.is_my_turn,
        board: Array.isArray(x.board) ? x.board : [],
        my_hand: Array.isArray(x.my_hand) ? x.my_hand : [],
        opponent_hand_count: x.opponent_hand_count != null ? Number(x.opponent_hand_count) : 0,
        opponent_server_id: x.opponent_server_id,
        last_action: x.last_action || null,
        ended: false,
        result: null,
      };
    } else {
      Object.assign(cur, {
        session_id: x.session_id,
        turn_no: x.turn_no,
        turn_server_id: x.turn_server_id,
        is_my_turn: !!x.is_my_turn,
        board: Array.isArray(x.board) ? x.board : cur.board,
        my_hand: Array.isArray(x.my_hand) ? x.my_hand : cur.my_hand,
        opponent_hand_count: x.opponent_hand_count != null ? Number(x.opponent_hand_count) : cur.opponent_hand_count,
        opponent_server_id: x.opponent_server_id != null ? x.opponent_server_id : cur.opponent_server_id,
        last_action: x.last_action != null ? x.last_action : cur.last_action,
      });
    }
    renderCurrentTab();
  });

  NUI.on('battlePvpEnded', (p) => {
    const cur = global.AppState.battle;
    const payload = p || {};
    if (cur && cur.mode === 'pvp') {
      cur.ended = true;
      cur.result = payload;
      if (Array.isArray(payload.final_board)) {
        cur.board = payload.final_board;
      }
      cur.is_my_turn = false;
      renderCurrentTab();
      return;
    }
    global.AppState.battle = null;
    global.AppState.battleVirtual.connectedPeerId = null;
    global.AppState.battleVirtual.isCaller = null;
    global.AppState.battleVirtual.waiting = false;
    global.AppState.battleVirtual.matchPrepLabel = '';
    renderCurrentTab();
  });

  NUI.on('battlePvpError', (p) => {
    const r = p && p.reason;
    showError(PVP_ERROR_REASON_JA[r] || `対戦エラー（${r || 'unknown'}）`);
    renderCurrentTab();
  });

  NUI.on('bookData', (payload) => {
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : 'データ取得に失敗しました');
      return;
    }
    const d = payload.data || {};
    if (typeof global.Deck?.resetMutationTransport === 'function') {
      global.Deck.resetMutationTransport();
    }
    global.AppState.player = d.player || null;
    global.AppState.matchHistory = Array.isArray(d.match_history) ? d.match_history : [];
    global.AppState.cards = Array.isArray(d.cards) ? d.cards : [];
    global.AppState.cardsMaster = Array.isArray(d.cardsMaster) ? d.cardsMaster : [];
    global.AppState.decks = Array.isArray(d.decks) ? d.decks : [];
    const debounce = Number(d.ui && d.ui.autoSaveDebounceMs);
    const psid = Number(d.ui && d.ui.playerServerId);
    global.AppState.ui = {
      autoSaveDebounceMs: Number.isFinite(debounce) && debounce >= 0 ? debounce : 500,
      playerServerId: Number.isFinite(psid) && psid >= 1 ? psid : null,
      allow_debug_battle: !!(d.ui && d.ui.allow_debug_battle),
      wire_log: !!(d.ui && d.ui.wire_log),
    };
    global.__tcgWireLog = !!(d.ui && d.ui.wire_log);

    const prevLobby = global.AppState.battleCpuLobby || {};
    global.AppState.battleCpuLobby = {
      debugLobbyOpen: !!prevLobby.debugLobbyOpen,
      lookupLabel: typeof prevLobby.lookupLabel === 'string' ? prevLobby.lookupLabel : '',
    };
    global.AppState.battle = null;
    if (d.battleCpuSession && typeof d.battleCpuSession === 'object') {
      global.AppState.battle = { mode: 'cpu', ...d.battleCpuSession };
    } else if (d.battlePvpSession && typeof d.battlePvpSession === 'object') {
      global.AppState.battle = { mode: 'pvp', ended: false, result: null, ...d.battlePvpSession };
    }

    global.AppState.battleVirtual = {
      waiting: false,
      connectedPeerId: null,
      isCaller: null,
      lastError: null,
      soloWireTest: false,
      soloPeerLabel: '',
      matchPrepLabel: '',
    };
    if (d.battleSession && d.battleSession.peer_server_id != null) {
      global.AppState.battleVirtual.connectedPeerId = Number(d.battleSession.peer_server_id);
    }

    const active = global.AppState.decks.find((x) => x.is_active === true || x.is_active === 1);
    global.AppState.activeDeckId = active ? active.id : null;
    global.AppState.activeDeck = d.activeDeck || null;
    global.AppState.currentDeckDetail = null;
    global.AppState.currentDeckId = null;

    renderHeader();
    renderCurrentTab();
    if (global.AppState.currentTab === 'deck') {
      ensureDeckSelection();
    }
  });

  NUI.on('deckSelected', (payload) => {
    if (typeof global.Deck?.resetMutationTransport === 'function') {
      global.Deck.resetMutationTransport();
    }
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : 'デッキ取得に失敗しました');
      return;
    }
    global.AppState.currentDeckDetail = payload.data || null;
    global.AppState.currentDeckId = payload.data ? payload.data.id : null;
    const adId = global.AppState.activeDeckId;
    if (payload.data && adId != null && payload.data.id === adId) {
      global.AppState.activeDeck = payload.data;
    }
    if (typeof global.Deck?.markSynced === 'function') {
      global.Deck.markSynced();
    }
    renderCurrentTab();
  });

  NUI.on('deckUpdated', (payload) => {
    if (typeof global.Deck?.onServerDeckUpdated === 'function') {
      global.Deck.onServerDeckUpdated(payload);
    }
    const curId = global.AppState.currentDeckId;
    if (payload && payload.success && payload.data && curId != null && payload.data.id !== curId) {
      return;
    }
    if (!payload || !payload.success) {
      showError(payload && payload.error ? payload.error : 'デッキ更新に失敗しました');
      renderCurrentTab();
      return;
    }
    global.AppState.currentDeckDetail = payload.data || null;
    const adId2 = global.AppState.activeDeckId;
    if (payload.data && adId2 != null && payload.data.id === adId2) {
      global.AppState.activeDeck = payload.data;
    }
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

    const curId = global.AppState.currentDeckId;
    if (curId && !global.AppState.decks.some((x) => x.id === curId)) {
      global.AppState.currentDeckId = null;
      global.AppState.currentDeckDetail = null;
      ensureDeckSelection();
    } else if (global.AppState.currentDeckDetail && curId) {
      const row = global.AppState.decks.find((x) => x.id === curId);
      if (row) global.AppState.currentDeckDetail.name = row.name;
    }

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

  global.jpTcgbookSwitchTab = switchTab;
  global.jpTcgbookShowError = showError;

  /** 仮想対戦／CPU 対戦中のみ確認。FiveM では window.confirm を使わない。 */
  global.jpTcgbookConfirmIfVirtualBattleAsync = async function (message) {
    const bv0 = global.AppState.battleVirtual;
    const peer = bv0 && bv0.connectedPeerId;
    if (
      peer == null &&
      !(bv0 && bv0.soloWireTest) &&
      !isCpuDuelActive() &&
      !isPvpDuelActive()
    ) {
      return true;
    }
    return openTcgConfirm(message);
  };
})(window);

/**
 * 対戦タブ（使用デッキ準備・仮想ロビー・デバッグCPU対戦）
 * グローバル: window.Battle
 */
(function (global) {
  const NUI = global.NUI;
  const api = global.api;
  const DECK_SIZE = 10;

  /** デバッグ盤面: 選択中の手札インデックス（0-based）。配置後にサーバー状態でリセット */
  let dbgSelectedHand = null;

  function $(sel) {
    return document.querySelector(sel);
  }

  function countFilled(detail) {
    if (!detail || !Array.isArray(detail.slots)) return 0;
    let n = 0;
    for (const s of detail.slots) {
      if (s && s.card) n++;
    }
    return n;
  }

  function deckPower(detail) {
    if (!detail || !Array.isArray(detail.slots)) return 0;
    let p = 0;
    for (const s of detail.slots) {
      const c = s && s.card;
      if (!c) continue;
      p += Math.max(
        Number(c.stat_top),
        Number(c.stat_right),
        Number(c.stat_bottom),
        Number(c.stat_left),
      );
    }
    return p;
  }

  function playerServerIdUi() {
    const v = global.AppState.ui && global.AppState.ui.playerServerId;
    if (v == null || v === '') return null;
    const n = Number(v);
    return Number.isFinite(n) && n >= 1 ? n : null;
  }

  function allowDebugBattleUi() {
    return !!(global.AppState.ui && global.AppState.ui.allow_debug_battle);
  }

  function renderReadinessSection(activeId, detail, compact) {
    const rating =
      global.AppState.player && global.AppState.player.rating != null
        ? global.AppState.player.rating
        : '—';

    if (activeId == null) {
      return (
        '<section class="battle-section">' +
        '<p class="battle-lead">使用デッキ（★）が設定されていません。</p>' +
        '<p class="battle-hint">デッキ編成で 10 枚揃ったデッキを「使用デッキに設定」してください。</p>' +
        '<button type="button" class="btn primary battle-goto" data-goto-deck>デッキ編成へ</button>' +
        '</section>'
      );
    }

    const loading = !detail || !detail.slots;
    if (loading) {
      return (
        '<section class="battle-section">' +
        '<div class="battle-readiness battle-readiness-loading">' +
        '<div class="battle-skeleton-title"></div>' +
        '<div class="battle-skeleton-line wide"></div>' +
        '<div class="battle-skeleton-line"></div>' +
        '</div>' +
        '<p class="battle-hint">アクティブデッキを読み込み中です。</p>' +
        '<button type="button" class="btn primary battle-refresh-deck">再読込</button>' +
        '</section>'
      );
    }

    const filled = countFilled(detail);
    const name = detail.name ? escapeHtml(detail.name) : '—';
    const ready = filled >= DECK_SIZE;
    const pwr = deckPower(detail);
    const statusClass = ready ? 'ready' : 'warn';
    const statusLabel = ready ? '対戦準備OK（10枚）' : `枚数不足（${filled} / ${DECK_SIZE}）`;

    let rows =
      `<div class="battle-readiness-row"><span>状態</span><strong>${escapeHtml(statusLabel)}</strong></div>` +
      `<div class="battle-readiness-row"><span>レート</span><strong>${escapeHtml(String(rating))}</strong></div>`;
    if (ready) {
      rows += `<div class="battle-readiness-row"><span>総合PWR</span><strong>${pwr}</strong></div>`;
    }

    const inner =
      `<div class="battle-readiness ${statusClass}">` +
      `<div class="battle-readiness-title">使用デッキ</div>` +
      `<div class="battle-deck-name">${name}</div>` +
      rows +
      `</div>` +
      '<button type="button" class="btn battle-goto subtle" data-goto-deck>デッキを確認・編集</button>';

    if (compact) {
      return `<section class="battle-section battle-readiness-compact">${inner}</section>`;
    }
    return `<section class="battle-section">${inner}</section>`;
  }

  function renderLobbySection(bv) {
    const sid = playerServerIdUi();
    const sidLabel = sid != null ? String(sid) : NUI.IS_FIVEM ? '—' : String(101);

    if (bv.connectedPeerId != null || bv.soloWireTest) {
      const peerLabel = bv.soloWireTest
        ? escapeHtml(bv.soloPeerLabel || 'ソロ検証（2人目なし）')
        : escapeHtml(String(bv.connectedPeerId));
      const role = bv.soloWireTest
        ? 'ソロ検証'
        : bv.isCaller === true
          ? '呼び出し側'
          : bv.isCaller === false
            ? '待受側'
            : '接続済み';
      const peerLine = bv.soloWireTest
        ? `<strong>${peerLabel}</strong>`
        : `相手のサーバーID <strong>${peerLabel}</strong>`;
      const hint = bv.soloWireTest
        ? '実プレイヤーはいません。通信経路と UI のみの確認です。盤面・報酬は未実装です。'
        : 'マッチ成立後は全画面アリーナで対戦します（サーバー権威・PHASE A）。敗北時のカードコピー付与は別 PHASE。';
      return (
        '<section class="battle-section battle-lobby">' +
        '<h3 class="battle-section-title">仮想対戦</h3>' +
        `<div class="battle-virtual-on"><p class="battle-lead">${escapeHtml(role)}：${peerLine}</p>` +
        `<p class="battle-hint">${hint}</p>` +
        '<button type="button" class="btn danger battle-leave">切断する</button></div>' +
        '</section>'
      );
    }

    const waitingOn = bv.waiting === true;
    return (
      '<section class="battle-section battle-lobby">' +
      '<h3 class="battle-section-title">仮想対戦（デバッグ／検証）</h3>' +
      '<p class="battle-hint">近距離招待は使わず、<strong>相手プレイヤーのサーバーID（番号）</strong>で呼び出します。待ち受ける側は「招待待機」を ON にして番号を伝え、呼ぶ側がその番号を入力します。</p>' +
      `<div class="battle-my-id"><span class="label">あなたの番号（サーバーID）</span>` +
      `<span class="num">${escapeHtml(sidLabel)}</span></div>` +
      `<div class="battle-wait-row">` +
      `<button type="button" class="btn ${waitingOn ? '' : 'primary'} battle-wait-toggle">${waitingOn ? '招待待機をやめる' : '招待待機を開始'}</button>` +
      `</div>` +
      `<div class="battle-call-row">` +
      `<label class="battle-call-label"><span>相手の番号</span>` +
      `<input type="number" min="1" step="1" class="battle-call-input" id="battleCallInput" placeholder="例: 12" aria-label="相手のサーバーID"></label>` +
      `<button type="button" class="btn primary battle-call-btn">呼び出す</button>` +
      `</div>` +
      (allowDebugBattleUi()
        ? '<div class="battle-solo-wire-row">' +
          '<button type="button" class="btn subtle battle-solo-wire-btn">1人で仮想接続の往復を試す</button>' +
          '<p class="battle-hint">友達のクライアントは不要です（<code>Config.DebugCommands</code> 有効時のみサーバが応答）。' +
          'F8 や <code>[jp-tcgbook][wire]</code> ログで NUI→client→server→client→NUI を追えます。</p>' +
          '</div>'
        : '') +
      '<p class="battle-next">コマンド <code>/tcg_battleid</code>（デバッグ権限）でも自分の番号を確認できます。</p>' +
      '</section>'
    );
  }

  /** Config.DebugCommands 時のみ（サーバーが allow_debug_battle で通知） */
  function renderDebugLobbySection(bc) {
    const open = !!(bc && bc.debugLobbyOpen);
    const lookupLabel = bc && bc.lookupLabel ? escapeHtml(bc.lookupLabel) : '';
    let panel = '';
    if (open) {
      panel =
        '<div class="battle-dbg-lobby-panel">' +
        '<p class="battle-hint">検索はオンライン確認をしません（応答のみの検証用）。「CPU対戦を開始」でサーバーが CPU を相手にした対戦を開始します。</p>' +
        '<div class="battle-call-row battle-dbg-lookup-row">' +
        '<label class="battle-call-label"><span>検索するサーバーID</span>' +
        '<input type="number" min="1" step="1" class="battle-call-input" id="battleDbgLookupInput" placeholder="例: 99" aria-label="検索するサーバーID"></label>' +
        '<button type="button" class="btn battle-dbg-lookup-btn">検索</button>' +
        '</div>' +
        (lookupLabel
          ? `<p class="battle-dbg-lookup-result"><strong>検索結果:</strong> ${lookupLabel}</p>`
          : '') +
        '<div class="battle-wait-row">' +
        '<button type="button" class="btn primary battle-dbg-start-cpu">CPU対戦を開始</button>' +
        '</div>' +
        '</div>';
    }
    return (
      '<section class="battle-section battle-dbg-lobby">' +
      '<h3 class="battle-section-title">デバッグ用ロビー</h3>' +
      '<p class="battle-hint"><code>Config.DebugCommands</code> が有効なときのみ表示されます。本番 PvP とは別経路です。</p>' +
      `<label class="battle-dbg-toggle"><input type="checkbox" id="battleDbgLobbyToggle" ${open ? 'checked' : ''}/> デバッグ用ロビーを表示する</label>` +
      panel +
      '</section>'
    );
  }

  /** デッキ／コレクションと同じ 4 方向ミニステ＋中央イラスト（.mini-stat + CardUtil.applyMaxHighlight） */
  function dbgSlotArtHtml(c, extraClass) {
    const c2 = c || {};
    const t = Number(c2.stat_top) || 0;
    const r = Number(c2.stat_right) || 0;
    const b = Number(c2.stat_bottom) || 0;
    const l = Number(c2.stat_left) || 0;
    const cls = extraClass ? `battle-dbg-slot-art ${extraClass}` : 'battle-dbg-slot-art';
    return (
      `<div class="${cls}" data-stat-top="${t}" data-stat-right="${r}" data-stat-bottom="${b}" data-stat-left="${l}">` +
      `<span class="mini-stat s-top">${t}</span>` +
      `<span class="mini-stat s-right">${r}</span>` +
      `<span class="mini-stat s-bottom">${b}</span>` +
      `<span class="mini-stat s-left">${l}</span>` +
      `${dbgCardArtHtml(c2)}` +
      `</div>`
    );
  }

  function applyDbgSlotMaxHighlights(root) {
    const CU = global.CardUtil;
    if (!CU || typeof CU.applyMaxHighlight !== 'function') return;
    root.querySelectorAll('.battle-dbg-slot-art').forEach((el) => {
      const stats = {
        stat_top: Number(el.getAttribute('data-stat-top')),
        stat_right: Number(el.getAttribute('data-stat-right')),
        stat_bottom: Number(el.getAttribute('data-stat-bottom')),
        stat_left: Number(el.getAttribute('data-stat-left')),
      };
      if (!Number.isFinite(stats.stat_top)) return;
      CU.applyMaxHighlight(el, stats);
    });
  }

  /** @param {'cpu'|'pvp'} mode */
  function buildDbgStatusLineHtml(st, mode) {
    const opp = mode === 'pvp' ? '相手' : 'CPU';
    const turnLabel = st.turn === 'human' ? 'あなた' : opp;
    const fp = st.first_player === 'human' ? 'あなた' : opp;
    return `先攻: ${escapeHtml(fp)} ・ いまのターン: <strong>${escapeHtml(
      turnLabel,
    )}</strong> ・ ${escapeHtml(opp)}手札残: ${Number(st.cpu_hand_count) || 0}`;
  }

  /** 終了時のみ：メイン領域中央に重ね表示（対戦終了で state 消滅 → 再描画で DOM ごと消える） */
  /** @param {'cpu'|'pvp'} mode */
  function buildDbgResultOverlayHtml(st, mode) {
    if (st.phase !== 'ended' || !st.scores || !st.winner) return '';
    const opp = mode === 'pvp' ? '相手' : 'CPU';
    const w =
      st.winner === 'human'
        ? 'あなたの勝ち'
        : st.winner === 'cpu'
          ? `${opp} の勝ち`
          : '引き分け';
    const scoreLine = `スコア（盤の色＋手札）: あなた ${st.scores.human} vs ${opp} ${st.scores.cpu}`;
    return (
      `<div class="battle-arena-result-overlay" role="alertdialog" aria-modal="true" aria-labelledby="battleArenaResultTitle">` +
      `<div class="battle-arena-result-panel">` +
      `<h2 id="battleArenaResultTitle" class="battle-arena-result-title">${escapeHtml(w)}</h2>` +
      `<p class="battle-arena-result-score">${escapeHtml(scoreLine)}</p>` +
      `<p class="battle-arena-result-foot">上部の「対戦終了」でロビーに戻れます</p>` +
      `</div>` +
      `</div>`
    );
  }

  function buildDbgGridHtml(st, humanTurn, gridExtraClass) {
    const gcls = gridExtraClass ? `battle-dbg-grid ${gridExtraClass}` : 'battle-dbg-grid';
    let grid = `<div class="${gcls}" role="grid" aria-label="3x3盤面">`;
    for (let i = 1; i <= 9; i++) {
      const cell = getDbgBoardCell(st, i);
      let cls = 'battle-dbg-cell';
      let inner = '';
      let disabled = false;
      if (cell) {
        cls += cell.owner === 'human' ? ' owner-human' : ' owner-cpu';
        const c = cell.card || {};
        const nm = escapeHtml(c.name || c.card_id || '');
        const fullnm = escAttr(c.name || c.card_id || '');
        inner =
          `<div class="battle-dbg-cell-inner">` +
          `${dbgSlotArtHtml(c, 'battle-dbg-cell-slot')}` +
          `<span class="battle-dbg-cell-name" title="${fullnm}">${nm}</span>` +
          `</div>`;
      } else {
        cls += ' empty';
        inner = '<span class="battle-dbg-cell-placeholder">＋</span>';
        if (!humanTurn) disabled = true;
      }
      grid +=
        `<button type="button" class="${cls}" data-dbg-cell="${i}" ${disabled ? 'disabled' : ''} aria-label="マス ${i}">${inner}</button>`;
    }
    grid += '</div>';
    return grid;
  }

  function buildDbgHandHtml(st, handRowClass) {
    const handArr = Array.isArray(st.human_hand) ? st.human_hand : [];
    if (dbgSelectedHand != null && (dbgSelectedHand < 0 || dbgSelectedHand >= handArr.length)) {
      dbgSelectedHand = null;
    }
    const rowCls = handRowClass ? `battle-dbg-hand ${handRowClass}` : 'battle-dbg-hand';
    let handHtml = `<div class="${rowCls}">`;
    handArr.forEach((c, i) => {
      const sel = dbgSelectedHand === i ? ' selected' : '';
      const c2 = c || {};
      const tit = escAttr(c2.name || c2.card_id || '');
      handHtml +=
        `<button type="button" class="battle-dbg-hand-card${sel}" data-dbg-hand="${i}" title="${tit}">` +
        `${dbgSlotArtHtml(c2, 'battle-dbg-hand-slot')}` +
        `<span class="hn">${escapeHtml(c2.name || c2.card_id || '')}</span>` +
        `</button>`;
    });
    handHtml += '</div>';
    return handHtml;
  }

  function buildDbgLogHtml(st, logWrapClass) {
    const logs = Array.isArray(st.log) ? st.log.slice(-14) : [];
    const lw = logWrapClass ? `battle-dbg-log ${logWrapClass}` : 'battle-dbg-log';
    let logHtml = `<div class="${lw}" aria-live="polite"><strong>ログ</strong><ul>`;
    logs.forEach((line) => {
      logHtml += `<li>${escapeHtml(line)}</li>`;
    });
    logHtml += '</ul></div>';
    return logHtml;
  }

  /** 全画面対戦レイヤー用 HTML（ロビーとは別） */
  /** @param {'cpu'|'pvp'} mode */
  function renderArenaDocument(st, mode) {
    const playing = st.phase === 'playing';
    const humanTurn = playing && st.turn === 'human';
    const statusLine = buildDbgStatusLineHtml(st, mode);
    const resultOverlay = buildDbgResultOverlayHtml(st, mode);
    const badge = mode === 'pvp' ? 'PVP' : 'DEBUG';
    const sub = mode === 'pvp' ? 'vs 相手 · PHASE A' : 'vs CPU · PHASE A';
    const grid = buildDbgGridHtml(st, humanTurn, 'battle-arena-grid');
    const handRow = buildDbgHandHtml(st, 'battle-arena-hand-row');
    const logHtml = buildDbgLogHtml(st, 'battle-arena-log-inner');

    return (
      `<div class="battle-arena-shell battle-dbg-theme">` +
      `<div class="battle-arena-bg" aria-hidden="true"></div>` +
      `<div class="battle-arena-vignette" aria-hidden="true"></div>` +
      `<div class="battle-arena-frame">` +
      `<header class="battle-arena-top">` +
      `<div class="battle-arena-brand">` +
      `<span class="battle-arena-badge">${escapeHtml(badge)}</span>` +
      `<span class="battle-arena-title">DUEL</span>` +
      `<span class="battle-arena-sub">${escapeHtml(sub)}</span>` +
      `</div>` +
      `<button type="button" class="btn danger battle-arena-quit">対戦終了</button>` +
      `</header>` +
      `<div class="battle-arena-main-wrap">` +
      `<div class="battle-arena-body">` +
      `<div class="battle-arena-upper">` +
      `<aside class="battle-arena-column battle-arena-column-log">${logHtml}</aside>` +
      `<div class="battle-arena-column battle-arena-column-board">` +
      `<div class="battle-arena-status battle-hint">${statusLine}</div>` +
      `${grid}` +
      `<p class="battle-arena-footnote">隣接比較・配置直後のみ奪取・連鎖なし</p>` +
      `</div>` +
      `</div>` +
      `<div class="battle-arena-hand-bar">` +
      `<div class="battle-arena-hand-bar-head">` +
      `<span class="battle-dbg-hand-label battle-arena-hand-head">手札</span>` +
      `<span class="battle-arena-hand-hint">カードを選び、空マスをタップ（最大5枚・横並び）</span>` +
      `</div>` +
      `${handRow}` +
      `</div>` +
      `</div>` +
      `${resultOverlay}` +
      `</div>` +
      `</div>` +
      `</div>`
    );
  }

  /** @param {'cpu'|'pvp'} mode */
  function bindArenaGameplay(root, mode) {
    root.querySelectorAll('[data-dbg-hand]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const st =
          mode === 'pvp'
            ? global.AppState.battlePvp && global.AppState.battlePvp.state
            : global.AppState.battleCpu && global.AppState.battleCpu.state;
        if (!st || st.phase !== 'playing' || st.turn !== 'human') return;
        const i = parseInt(btn.getAttribute('data-dbg-hand') || '-1', 10);
        dbgSelectedHand = Number.isFinite(i) ? i : null;
        Battle.render();
      });
    });
    root.querySelectorAll('[data-dbg-cell]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const st =
          mode === 'pvp'
            ? global.AppState.battlePvp && global.AppState.battlePvp.state
            : global.AppState.battleCpu && global.AppState.battleCpu.state;
        if (!st || st.phase !== 'playing' || st.turn !== 'human') return;
        if (dbgSelectedHand == null) {
          if (typeof global.jpTcgbookShowError === 'function') {
            global.jpTcgbookShowError('先に手札のカードを選んでください');
          }
          return;
        }
        const cell = parseInt(btn.getAttribute('data-dbg-cell') || '0', 10);
        if (!Number.isFinite(cell) || cell < 1 || cell > 9) return;
        if (mode === 'pvp') {
          const sid = st.pvp_session_id;
          const seq = st.turn_seq;
          if (sid == null || seq == null) {
            if (typeof global.jpTcgbookShowError === 'function') {
              global.jpTcgbookShowError('対戦状態が不正です（再読込してください）');
            }
            return;
          }
          api.battlePvpPlace(cell, dbgSelectedHand, seq, sid);
        } else {
          api.battleDebugPlace(cell, dbgSelectedHand);
        }
        dbgSelectedHand = null;
      });
    });
    root.querySelector('.battle-arena-quit')?.addEventListener('click', () => {
      void (async () => {
        const fn = global.jpTcgbookConfirmIfVirtualBattleAsync;
        const msg =
          mode === 'pvp'
            ? '対戦を終了しますか？\n\n相手側のセッションも終了します。'
            : 'デバッグ対戦を終了しますか？';
        if (typeof fn === 'function' && !(await fn(msg))) return;
        if (mode === 'pvp') {
          api.battlePvpLeave();
        } else {
          api.battleDebugLeave();
        }
      })();
    });
    applyDbgSlotMaxHighlights(root);
  }

  /** @returns {{ st: object, mode: 'cpu'|'pvp' } | null} */
  function getArenaView() {
    const bp = global.AppState.battlePvp || {};
    if (bp.active && bp.state) return { st: bp.state, mode: 'pvp' };
    const bc = global.AppState.battleCpu || {};
    if (bc.active && bc.state) return { st: bc.state, mode: 'cpu' };
    return null;
  }

  function bindSectionHandlers(root) {
    root.querySelector('[data-goto-deck]')?.addEventListener('click', () => {
      if (typeof global.jpTcgbookSwitchTab === 'function') global.jpTcgbookSwitchTab('deck');
    });
    root.querySelector('.battle-refresh-deck')?.addEventListener('click', () => {
      const id = global.AppState.activeDeckId;
      if (id) api.selectDeck(id);
    });
    root.querySelector('.battle-wait-toggle')?.addEventListener('click', () => {
      const bv = global.AppState.battleVirtual;
      api.battleSetWaiting(!bv.waiting);
    });
    root.querySelector('.battle-call-btn')?.addEventListener('click', () => {
      const inp = root.querySelector('#battleCallInput');
      const raw = inp && 'value' in inp ? inp.value : '';
      const tid = parseInt(String(raw).trim(), 10);
      if (!Number.isFinite(tid) || tid < 1) {
        if (typeof global.jpTcgbookShowError === 'function') {
          global.jpTcgbookShowError('相手の番号を入力してください');
        }
        return;
      }
      api.battleCallById(tid);
    });
    root.querySelector('.battle-leave')?.addEventListener('click', () => {
      void (async () => {
        const fn = global.jpTcgbookConfirmIfVirtualBattleAsync;
        const bv = global.AppState.battleVirtual || {};
        const msg = bv.soloWireTest
          ? 'ソロ検証の仮想接続を終了しますか？'
          : '仮想対戦を終了しますか？\n\n相手側のセッションも終了します。誤操作防止のため確認しています。';
        if (typeof fn === 'function' && !(await fn(msg))) {
          return;
        }
        api.battleVirtualLeave();
      })();
    });

    root.querySelector('.battle-solo-wire-btn')?.addEventListener('click', () => {
      api.battleSoloVirtualWireTest();
    });

    root.querySelector('#battleDbgLobbyToggle')?.addEventListener('change', (e) => {
      const t = e.target;
      if (!global.AppState.battleCpu) global.AppState.battleCpu = {};
      global.AppState.battleCpu.debugLobbyOpen = !!(t && t.checked);
      Battle.render();
    });
    root.querySelector('.battle-dbg-lookup-btn')?.addEventListener('click', () => {
      const inp = root.querySelector('#battleDbgLookupInput');
      const raw = inp && 'value' in inp ? inp.value : '';
      const tid = parseInt(String(raw).trim(), 10);
      if (!Number.isFinite(tid) || tid < 1) {
        if (typeof global.jpTcgbookShowError === 'function') {
          global.jpTcgbookShowError('検索するサーバーID を入力してください');
        }
        return;
      }
      api.battleDebugLookupId(tid);
    });
    root.querySelector('.battle-dbg-start-cpu')?.addEventListener('click', () => {
      api.battleDebugStartCpu();
    });
  }

  function escapeHtml(s) {
    return String(s || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function escAttr(s) {
    const f = global.CardUtil && global.CardUtil.escapeHtmlAttr;
    return typeof f === 'function' ? f(s) : escapeHtml(s);
  }

  /** Lua→JSON で board が配列になった旧ペイロードとも整合（1〜9 はマス番号） */
  function getDbgBoardCell(st, idx1to9) {
    const b = st && st.board;
    if (b == null) return undefined;
    if (Array.isArray(b)) return b[idx1to9 - 1];
    const k = String(idx1to9);
    if (Object.prototype.hasOwnProperty.call(b, k)) return b[k];
    return b[idx1to9];
  }

  /** デバッグ対戦のカードに image_path（無ければマスタから） */
  function dbgCardImagePath(c) {
    if (!c) return '';
    const p = String(c.image_path || '').trim();
    if (p) return p;
    const id = c.card_id;
    const cm = global.AppState && Array.isArray(global.AppState.cardsMaster) ? global.AppState.cardsMaster : [];
    const m = cm.find((row) => row && row.card_id === id);
    return m && m.image_path ? String(m.image_path).trim() : '';
  }

  function dbgCardArtHtml(c) {
    const CU = global.CardUtil;
    if (!CU || typeof CU.cardArtMediaHtml !== 'function') return '';
    return CU.cardArtMediaHtml(c && c.card_id, dbgCardImagePath(c));
  }

  const Battle = {
    render() {
      const root = $('#battlePanel');
      const arenaRoot = $('#battleArenaRoot');
      const bookEl = document.querySelector('.book');

      const activeId = global.AppState.activeDeckId;
      const detail = global.AppState.activeDeck;
      const bv = global.AppState.battleVirtual || {};
      const arena = getArenaView();

      if (arenaRoot) {
        if (arena) {
          arenaRoot.hidden = false;
          arenaRoot.setAttribute('aria-hidden', 'false');
          arenaRoot.innerHTML = renderArenaDocument(arena.st, arena.mode);
          bindArenaGameplay(arenaRoot, arena.mode);
          bookEl?.classList.add('book--cpu-duel');
        } else {
          arenaRoot.hidden = true;
          arenaRoot.setAttribute('aria-hidden', 'true');
          arenaRoot.innerHTML = '';
          bookEl?.classList.remove('book--cpu-duel');
        }
      }

      if (!root) return;

      if (arena) {
        root.innerHTML =
          '<section class="battle-section battle-during-cpu">' +
          '<p class="battle-hint">対戦は全画面で表示されています。終了は対戦画面上部の「対戦終了」から行ってください。</p>' +
          '</section>';
        return;
      }

      let html = '';
      html += renderReadinessSection(activeId, detail, false);
      if (allowDebugBattleUi() && bv.connectedPeerId == null && !bv.soloWireTest) {
        html += renderDebugLobbySection(bc);
      }
      html += renderLobbySection(bv);
      html +=
        '<p class="battle-next footnote">仮想ロビーでマッチしたプレイヤー同士は同一ルール（PHASE A）で対戦できます。自動マッチングは別フェーズです。デバッグ時は「デバッグ用ロビー」から CPU 戦も利用できます。</p>';

      root.innerHTML = html;
      bindSectionHandlers(root);
    },
  };

  global.Battle = Battle;
})(window);

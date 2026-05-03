/**
 * 対戦タブ（使用デッキ準備・フリーバトルCPU練習・仮想ロビー・デバッグ用ロビー）
 * グローバル: window.Battle
 */
(function (global) {
  const NUI = global.NUI;
  const api = global.api;
  const CU = global.CardUtil;
  const DECK_SIZE = 10;

  /** デバッグ盤面: 選択中の手札インデックス（0-based）。配置後にサーバー状態でリセット */
  let dbgSelectedHand = null;

  function tt(key, vars) {
    return global.I18n && global.I18n.tf ? global.I18n.tf(key, vars) : key;
  }

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
        `<p class="battle-lead">${escapeHtml(tt('battle_no_deck_lead'))}</p>` +
        `<p class="battle-hint">${escapeHtml(tt('battle_no_deck_hint'))}</p>` +
        `<button type="button" class="btn primary battle-goto" data-goto-deck>${escapeHtml(tt('battle_goto_deck'))}</button>` +
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
        `<p class="battle-hint">${escapeHtml(tt('battle_loading_hint'))}</p>` +
        `<button type="button" class="btn primary battle-refresh-deck">${escapeHtml(tt('battle_refresh_deck'))}</button>` +
        '</section>'
      );
    }

    const filled = countFilled(detail);
    const name = detail.name
      ? escapeHtml(global.CardUtil.formatDeckDisplayName(detail.name))
      : '—';
    const ready = filled >= DECK_SIZE;
    const pwr = deckPower(detail);
    const statusClass = ready ? 'ready' : 'warn';
    const statusLabel = ready
      ? tt('battle_ready_ok')
      : tt('battle_ready_short', { filled, size: DECK_SIZE });

    let rows =
      `<div class="battle-readiness-row"><span>${escapeHtml(tt('battle_row_state'))}</span><strong>${escapeHtml(statusLabel)}</strong></div>` +
      `<div class="battle-readiness-row"><span>${escapeHtml(tt('battle_row_rating'))}</span><strong>${escapeHtml(String(rating))}</strong></div>`;
    if (ready) {
      rows += `<div class="battle-readiness-row"><span>${escapeHtml(tt('battle_row_pwr'))}</span><strong>${pwr}</strong></div>`;
    }

    const inner =
      `<div class="battle-readiness ${statusClass}">` +
      `<div class="battle-readiness-title">${escapeHtml(tt('battle_readiness_title'))}</div>` +
      `<div class="battle-deck-name">${name}</div>` +
      rows +
      `</div>` +
      `<button type="button" class="btn battle-goto subtle" data-goto-deck>${escapeHtml(tt('battle_review_deck'))}</button>`;

    if (compact) {
      return `<section class="battle-section battle-readiness-compact">${inner}</section>`;
    }
    return `<section class="battle-section">${inner}</section>`;
  }

  /** フリーバトル（CPU練習）— DebugCommands 不要。疑似通信・ソロ検証接続中はブロック */
  function renderPracticeCpuSection(activeId, detail, bv) {
    const bvSafe = bv || {};
    const blockedLobby =
      bvSafe.connectedPeerId != null || bvSafe.soloWireTest === true;

    if (activeId == null) {
      return (
        '<section class="battle-section battle-practice">' +
        `<h3 class="battle-section-title">${escapeHtml(tt('battle_section_practice'))}</h3>` +
        `<p class="battle-hint">${escapeHtml(tt('battle_practice_need_active_deck'))}</p>` +
        '</section>'
      );
    }

    const loading = !detail || !detail.slots;
    if (loading) {
      return (
        '<section class="battle-section battle-practice">' +
        `<h3 class="battle-section-title">${escapeHtml(tt('battle_section_practice'))}</h3>` +
        `<p class="battle-hint">${escapeHtml(tt('battle_loading_hint'))}</p>` +
        '</section>'
      );
    }

    const filled = countFilled(detail);
    const ready = filled >= DECK_SIZE;
    let hintHtml = escapeHtml(tt('battle_practice_hint'));
    if (blockedLobby) {
      hintHtml = escapeHtml(tt('battle_practice_blocked_virtual'));
    } else if (!ready) {
      hintHtml = escapeHtml(tt('battle_practice_need_full_deck', { filled, size: DECK_SIZE }));
    }

    const canStart = ready && !blockedLobby;
    const disabledAttr = canStart ? '' : ' disabled';

    return (
      '<section class="battle-section battle-practice">' +
      `<h3 class="battle-section-title">${escapeHtml(tt('battle_section_practice'))}</h3>` +
      `<p class="battle-hint">${hintHtml}</p>` +
      `<button type="button" class="btn primary battle-practice-start-cpu"${disabledAttr}>${escapeHtml(tt('battle_practice_start'))}</button>` +
      '</section>'
    );
  }

  function renderLobbySection(bv) {
    const sid = playerServerIdUi();
    const sidLabel = sid != null ? String(sid) : NUI.IS_FIVEM ? '—' : String(101);

    if (bv.connectedPeerId != null || bv.soloWireTest) {
      const peerLabel = bv.soloWireTest
        ? escapeHtml(bv.soloPeerLabel || tt('battle_peer_solo_label'))
        : escapeHtml(String(bv.connectedPeerId));
      const role = bv.soloWireTest
        ? tt('battle_mode_solo_verify')
        : bv.isCaller === true
          ? tt('battle_role_caller')
          : bv.isCaller === false
            ? tt('battle_role_callee')
            : tt('battle_connected');
      const peerLine = bv.soloWireTest
        ? `<strong>${peerLabel}</strong>`
        : tt('battle_peer_html', { id: peerLabel });
      const hint = bv.soloWireTest
        ? tt('battle_virtual_no_player_note')
        : tt('battle_virtual_after_match_note');
      const prep =
        bv.matchPrepLabel && String(bv.matchPrepLabel).trim()
          ? `<p class="battle-hint battle-match-prep">${escapeHtml(String(bv.matchPrepLabel))}</p>`
          : '';
      return (
        '<section class="battle-section battle-lobby">' +
        `<h3 class="battle-section-title">${escapeHtml(tt('battle_section_virtual'))}</h3>` +
        `<div class="battle-virtual-on"><p class="battle-lead">${escapeHtml(role)}：${peerLine}</p>` +
        prep +
        `<p class="battle-hint">${escapeHtml(hint)}</p>` +
        `<button type="button" class="btn danger battle-leave">${escapeHtml(tt('battle_disconnect'))}</button></div>` +
        '</section>'
      );
    }

    const waitingOn = bv.waiting === true;
    const peerAria = escapeHtml(tt('battle_label_peer_number'));
    return (
      '<section class="battle-section battle-lobby">' +
      `<h3 class="battle-section-title">${escapeHtml(tt('battle_section_debug_virtual'))}</h3>` +
      `<p class="battle-hint">${tt('battle_debug_virtual_hint')}</p>` +
      `<div class="battle-my-id"><span class="label">${escapeHtml(tt('battle_label_your_server_id'))}</span>` +
      `<span class="num">${escapeHtml(sidLabel)}</span></div>` +
      `<div class="battle-wait-row">` +
      `<button type="button" class="btn ${waitingOn ? '' : 'primary'} battle-wait-toggle">${escapeHtml(waitingOn ? tt('battle_wait_stop') : tt('battle_wait_start'))}</button>` +
      `</div>` +
      `<div class="battle-call-row">` +
      `<label class="battle-call-label"><span>${escapeHtml(tt('battle_label_peer_number'))}</span>` +
      `<input type="number" min="1" step="1" class="battle-call-input" id="battleCallInput" placeholder="${escAttr(tt('battle_call_placeholder'))}" aria-label="${peerAria}"></label>` +
      `<button type="button" class="btn primary battle-call-btn">${escapeHtml(tt('battle_call_btn'))}</button>` +
      `</div>` +
      `<p class="battle-next">${tt('battle_battleid_note')}</p>` +
      '</section>'
    );
  }

  /** Config.DebugCommands 時のみ（サーバーが allow_debug_battle で通知）。疑似PvPソロ等（CPU練習は別セクション） */
  function renderDebugLobbySection(bc) {
    const open = !!(bc && bc.debugLobbyOpen);
    const lookupLabel = bc && bc.lookupLabel ? escapeHtml(bc.lookupLabel) : '';
    let panel = '';
    if (open) {
      const dbgLookupAria = escapeHtml(tt('battle_debug_lookup_label'));
      panel =
        '<div class="battle-dbg-lobby-panel">' +
        `<p class="battle-hint">${tt('battle_debug_lobby_hint')}</p>` +
        '<div class="battle-call-row battle-dbg-lookup-row">' +
        `<label class="battle-call-label"><span>${escapeHtml(tt('battle_debug_lookup_label'))}</span>` +
        `<input type="number" min="1" step="1" class="battle-call-input" id="battleDbgLookupInput" placeholder="${escAttr(tt('battle_dbg_lookup_ph'))}" aria-label="${dbgLookupAria}"></label>` +
        `<button type="button" class="btn battle-dbg-lookup-btn">${escapeHtml(tt('battle_dbg_lookup_btn'))}</button>` +
        '</div>' +
        (lookupLabel
          ? `<p class="battle-dbg-lookup-result"><strong>${escapeHtml(tt('battle_dbg_lookup_result'))}</strong> ${lookupLabel}</p>`
          : '') +
        '<div class="battle-call-row battle-wait-row">' +
        `<button type="button" class="btn primary battle-pvp-start-solo">${escapeHtml(tt('battle_dbg_start_pvp_solo'))}</button>` +
        '</div>' +
        '</div>';
    }
    return (
      '<section class="battle-section battle-dbg-lobby">' +
      `<h3 class="battle-section-title">${escapeHtml(tt('battle_debug_panel_title'))}</h3>` +
      `<p class="battle-hint">${tt('battle_debug_panel_note')}</p>` +
      `<label class="battle-dbg-toggle"><input type="checkbox" id="battleDbgLobbyToggle" ${open ? 'checked' : ''}/> ${escapeHtml(tt('battle_debug_toggle_label'))}</label>` +
      panel +
      '</section>'
    );
  }

  /** デッキ／コレクションと同じ 4 方向ミニステ＋中央イラスト（.mini-stat + CardUtil.applyMaxHighlight） */
  /** @param {string} [artWrapClass] 指定時はイラストのみこのクラスでラップ（アリーナ手札で画像領域だけ縮小するため） */
  function dbgSlotArtHtml(c, extraClass, artWrapClass) {
    const c2 = c || {};
    const t = Number(c2.stat_top) || 0;
    const r = Number(c2.stat_right) || 0;
    const b = Number(c2.stat_bottom) || 0;
    const l = Number(c2.stat_left) || 0;
    const cls = extraClass ? `battle-dbg-slot-art ${extraClass}` : 'battle-dbg-slot-art';
    const rawArt = dbgCardArtHtml(c2);
    const artHtml = artWrapClass ? `<div class="${artWrapClass}">${rawArt}</div>` : rawArt;
    return (
      `<div class="${cls}" data-stat-top="${t}" data-stat-right="${r}" data-stat-bottom="${b}" data-stat-left="${l}">` +
      `<span class="mini-stat s-top">${t}</span>` +
      `<span class="mini-stat s-right">${r}</span>` +
      `<span class="mini-stat s-bottom">${b}</span>` +
      `<span class="mini-stat s-left">${l}</span>` +
      artHtml +
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
    const opp =
      mode === 'pvp' ? tt('battle_opp_pvp') : tt('battle_opp_cpu');
    if (mode === 'pvp' && st.pvp_status_plain) {
      return escapeHtml(st.pvp_status_plain);
    }
    const you = tt('battle_you');
    const turnLabel = st.turn === 'human' ? you : opp;
    const fp = st.first_player === 'human' ? you : opp;
    return tt('battle_line_first_turn', {
      fp: escapeHtml(fp),
      turn: escapeHtml(turnLabel),
      opp: escapeHtml(opp),
      n: Number(st.cpu_hand_count) || 0,
    });
  }

  /** 終了時のみ：メイン領域中央に重ね表示（対戦終了で state 消滅 → 再描画で DOM ごと消える） */
  /** @param {'cpu'|'pvp'} mode */
  function buildDbgResultOverlayHtml(st, mode) {
    if (st.phase !== 'ended' || !st.scores || !st.winner) return '';
    const opp =
      mode === 'pvp' ? tt('battle_opp_pvp') : tt('battle_opp_cpu');
    const w =
      st.winner === 'human'
        ? tt('battle_result_win')
        : st.winner === 'cpu'
          ? tt('battle_result_lose', { opp })
          : tt('battle_result_draw');
    const scoreLine = tt('battle_score_line', {
      h: st.scores.human,
      opp,
      c: st.scores.cpu,
    });
    let policyHint = '';
    if (mode === 'pvp') {
      if (st.is_real_pvp === false) {
        policyHint =
          `<p class="battle-arena-result-hint">${escapeHtml(tt('battle_hint_pseudo_off'))}</p>`;
      } else if (st.is_real_pvp === true && st.winner === 'human') {
        policyHint =
          `<p class="battle-arena-result-hint">${escapeHtml(tt('battle_hint_win_no_card'))}</p>`;
      }
    }
    const defeatCopy =
      mode === 'pvp' && st.defeat_copy_received && st.defeat_copy_card_name
        ? `<p class="battle-arena-result-copy">${escapeHtml(tt('battle_defeat_copy'))} <strong>${escapeHtml(
            String(st.defeat_copy_card_name),
          )}</strong></p>`
        : '';
    const foot =
      mode === 'pvp'
        ? `<p class="battle-arena-result-foot">${escapeHtml(tt('battle_foot_back_tab'))}</p>` +
          `<button type="button" class="btn primary battle-pvp-result-dismiss">${escapeHtml(tt('battle_btn_back_tab'))}</button>`
        : `<p class="battle-arena-result-foot">${escapeHtml(tt('battle_foot_cpu_end'))}</p>`;
    return (
      `<div class="battle-arena-result-overlay" role="alertdialog" aria-modal="true" aria-labelledby="battleArenaResultTitle">` +
      `<div class="battle-arena-result-panel">` +
      `<h2 id="battleArenaResultTitle" class="battle-arena-result-title">${escapeHtml(w)}</h2>` +
      `<p class="battle-arena-result-score">${escapeHtml(scoreLine)}</p>` +
      policyHint +
      defeatCopy +
      foot +
      `</div>` +
      `</div>`
    );
  }

  /** @param {{ arenaLarge?: boolean }} [opts] */
  function buildDbgGridHtml(st, humanTurn, gridExtraClass, opts) {
    const arenaLarge = !!(opts && opts.arenaLarge);
    const gcls = gridExtraClass ? `battle-dbg-grid ${gridExtraClass}` : 'battle-dbg-grid';
    let grid = `<div class="${gcls}" role="grid" aria-label="${escAttr(tt('battle_grid_aria'))}">`;
    for (let i = 1; i <= 9; i++) {
      const cell = getDbgBoardCell(st, i);
      let cls = 'battle-dbg-cell';
      let inner = '';
      let disabled = false;
      if (cell) {
        cls += cell.owner === 'human' ? ' owner-human' : ' owner-cpu';
        const c = cell.card || {};
        const locNm = dbgLocalizedCardName(c);
        const nm =
          `<span class="card-name battle-cell-card-name"><span class="card-name-inner">${escapeHtml(locNm || c.card_id || '')}</span></span>`;
        const fullnm = escAttr(locNm || c.card_id || '');
        const rk = c.rank != null && String(c.rank) !== '' ? escapeHtml(String(c.rank)) : '';
        const slotCls = arenaLarge ? 'battle-dbg-cell-slot battle-arena-cell-slot' : 'battle-dbg-cell-slot';
        if (arenaLarge) {
          inner =
            `<div class="battle-dbg-cell-inner">` +
            `${dbgSlotArtHtml(c, slotCls)}` +
            `<div class="battle-dbg-cell-meta">` +
            `<span class="battle-dbg-cell-name" title="${fullnm}">${nm}</span>` +
            (rk ? `<span class="battle-dbg-cell-rank">${rk}</span>` : '') +
            `</div></div>`;
        } else {
          inner =
            `<div class="battle-dbg-cell-inner">` +
            `${dbgSlotArtHtml(c, slotCls)}` +
            `<span class="battle-dbg-cell-name" title="${fullnm}">${nm}</span>` +
            `</div>`;
        }
      } else {
        cls += ' empty';
        inner = '<span class="battle-dbg-cell-placeholder">＋</span>';
        if (!humanTurn) disabled = true;
      }
      grid +=
        `<button type="button" class="${cls}" data-dbg-cell="${i}" ${disabled ? 'disabled' : ''} aria-label="${escAttr(tt('battle_cell_aria', { i }))}">${inner}</button>`;
    }
    grid += '</div>';
    return grid;
  }

  function buildDbgHandHtml(st, handRowClass, handInteractive) {
    const handArr = Array.isArray(st.human_hand) ? st.human_hand : [];
    if (dbgSelectedHand != null && (dbgSelectedHand < 0 || dbgSelectedHand >= handArr.length)) {
      dbgSelectedHand = null;
    }
    const rowCls = handRowClass ? `battle-dbg-hand ${handRowClass}` : 'battle-dbg-hand';
    const hi = handInteractive !== false;
    let handHtml = `<div class="${rowCls}">`;
    handArr.forEach((c, i) => {
      const sel = dbgSelectedHand === i ? ' selected' : '';
      const c2 = c || {};
      const locH = dbgLocalizedCardName(c2);
      const tit = escAttr(locH || c2.card_id || '');
      const dis = !hi ? ' disabled' : '';
      const star =
        dbgSelectedHand === i ? `<span class="battle-dbg-hand-pick-star" aria-hidden="true">★</span>` : '';
      const rk =
        c2.rank != null && String(c2.rank) !== ''
          ? `<span class="hs">${escapeHtml(String(c2.rank))}</span>`
          : '';
      handHtml +=
        `<button type="button" class="battle-dbg-hand-card${sel}${dis}" data-dbg-hand="${i}" title="${tit}" ${!hi ? 'disabled' : ''}>` +
        star +
        `${dbgSlotArtHtml(c2, 'battle-dbg-hand-slot', 'battle-dbg-hand-art')}` +
        `<span class="hn card-name"><span class="card-name-inner">${escapeHtml(locH || c2.card_id || '')}</span></span>` +
        rk +
        `</button>`;
    });
    handHtml += '</div>';
    return handHtml;
  }

  /** サーバーが送る { key, ...params } またはレガシー文字列を現在 UI 言語で表示 */
  function formatBattleLogLine(line) {
    if (line && typeof line === 'object' && !Array.isArray(line) && typeof line.key === 'string') {
      const vars = Object.assign({}, line);
      delete vars.key;
      return tt(line.key, vars);
    }
    return String(line == null ? '' : line);
  }

  function buildDbgLogHtml(st, logWrapClass) {
    const logs = Array.isArray(st.log) ? st.log.slice(-14) : [];
    const lw = logWrapClass ? `battle-dbg-log ${logWrapClass}` : 'battle-dbg-log';
    let logHtml = `<div class="${lw}" aria-live="polite"><strong>${escapeHtml(tt('battle_log_head'))}</strong><ul>`;
    logs.forEach((line) => {
      logHtml += `<li>${escapeHtml(formatBattleLogLine(line))}</li>`;
    });
    logHtml += '</ul></div>';
    return logHtml;
  }

  /** 全画面対戦レイヤー用 HTML（ロビーとは別） */
  /** @param {'cpu'|'pvp'} mode */
  /** @param {object} b AppState.battle（mode==='pvp'） */
  function pvpToArenaSt(b) {
    if (!b || b.mode !== 'pvp') return null;
    const ended = !!b.ended;
    const playing = !ended;
    const boardObj = {};
    const arr = Array.isArray(b.board) ? b.board : [];
    for (let i = 1; i <= 9; i++) {
      const cell = arr[i - 1];
      if (cell && cell.card) {
        boardObj[String(i)] = {
          owner: cell.is_mine ? 'human' : 'cpu',
          card: cell.card,
        };
      }
    }
    let scores;
    let winner;
    let pvpPlain;
    if (ended && b.result) {
      scores = {
        human: b.result.my_score,
        cpu: b.result.opponent_score,
      };
      if (b.result.outcome === 'win') winner = 'human';
      else if (b.result.outcome === 'lose') winner = 'cpu';
      else winner = 'draw';
      pvpPlain = tt('battle_pvp_status_end', {
        my: b.result.my_score,
        op: b.result.opponent_score,
      });
    } else {
      const who = b.is_my_turn ? tt('battle_you') : tt('battle_opp_pvp');
      pvpPlain = tt('battle_pvp_status_playing', {
        who,
        n: Number(b.opponent_hand_count) || 0,
      });
    }
    const res = ended && b.result ? b.result : null;
    const defeatReceived = !!(res && res.defeat_copy_received);
    let defeatName = '';
    if (defeatReceived) {
      const cid = typeof res.defeat_copy_card_id === 'string' ? res.defeat_copy_card_id : '';
      const cm = global.AppState && Array.isArray(global.AppState.cardsMaster) ? global.AppState.cardsMaster : [];
      const row = cid ? cm.find((x) => x && x.card_id === cid) : null;
      if (row && CU && typeof CU.getLocalizedCardName === 'function') {
        defeatName = CU.getLocalizedCardName(row) || cid;
      } else if (typeof res.defeat_copy_card_name === 'string' && res.defeat_copy_card_name !== '') {
        defeatName = res.defeat_copy_card_name;
      } else {
        defeatName = cid;
      }
    }
    const isRealPvp =
      res && typeof res.is_real_pvp === 'boolean' ? res.is_real_pvp : undefined;
    return {
      phase: ended ? 'ended' : 'playing',
      turn: playing && b.is_my_turn ? 'human' : 'cpu',
      first_player: 'human',
      board: boardObj,
      human_hand: Array.isArray(b.my_hand) ? b.my_hand : [],
      cpu_hand_count: b.opponent_hand_count || 0,
      scores,
      winner,
      log: [],
      pvp_status_plain: pvpPlain,
      defeat_copy_received: defeatReceived,
      defeat_copy_card_name: defeatName,
      is_real_pvp: isRealPvp,
    };
  }

  function renderArenaDocument(st, mode) {
    const playing = st.phase === 'playing';
    const humanTurn = playing && st.turn === 'human';
    const statusLine = buildDbgStatusLineHtml(st, mode);
    const resultOverlay = buildDbgResultOverlayHtml(st, mode);
    const badge = mode === 'pvp' ? 'PVP' : 'DEBUG';
    const sub = mode === 'pvp' ? tt('battle_sub_pvp') : tt('battle_sub_cpu');
    const grid = buildDbgGridHtml(st, humanTurn, 'battle-arena-grid', { arenaLarge: true });
    const handRow = buildDbgHandHtml(st, 'battle-arena-hand-col', humanTurn);
    const quitLabel =
      mode === 'pvp' ? (playing ? tt('battle_resign') : tt('battle_end')) : tt('battle_quit_cpu');
    const logHtml = buildDbgLogHtml(st, 'battle-arena-log-inner');
    const arenaRes =
      typeof global.GetParentResourceName === 'function'
        ? global.GetParentResourceName()
        : 'jp-tcgbook';
    const duelBackCssUrl = `https://cfx-nui-${arenaRes}/html/assets/duel_back.png`;
    const pvpInvalidBatchBtn =
      allowDebugBattleUi() && mode === 'pvp' && playing
        ? `<button type="button" class="btn battle-arena-pvp-invalid-batch" title="${escAttr(tt('battle_invalid_batch_title'))}">${escapeHtml(tt('battle_invalid_batch_btn'))}</button>`
        : '';

    return (
      `<div class="battle-arena-shell battle-dbg-theme" style="--battle-duel-back: url(${duelBackCssUrl})">` +
      `<div class="battle-arena-bg" aria-hidden="true"></div>` +
      `<div class="battle-arena-vignette" aria-hidden="true"></div>` +
      `<div class="battle-arena-frame">` +
      `<header class="battle-arena-top">` +
      `<div class="battle-arena-brand">` +
      `<span class="battle-arena-badge">${escapeHtml(badge)}</span>` +
      `<span class="battle-arena-title">DUEL</span>` +
      `<span class="battle-arena-sub">${escapeHtml(sub)}</span>` +
      `</div>` +
      `<div class="battle-arena-actions">` +
      pvpInvalidBatchBtn +
      `<button type="button" class="btn danger battle-arena-quit">${escapeHtml(quitLabel)}</button>` +
      `</div>` +
      `</header>` +
      `<div class="battle-arena-main-wrap">` +
      `<div class="battle-arena-body">` +
      `<div class="battle-arena-upper battle-arena-three-col">` +
      `<aside class="battle-arena-column battle-arena-column-log">${logHtml}</aside>` +
      `<div class="battle-arena-column battle-arena-column-board battle-arena-column-center">` +
      `<div class="battle-arena-status battle-hint">${statusLine}</div>` +
      `<div class="battle-arena-grid-wrap">${grid}</div>` +
      `<p class="battle-arena-footnote">${escapeHtml(tt('battle_footnote'))}</p>` +
      `</div>` +
      `<aside class="battle-arena-column battle-arena-column-hand">` +
      `<div class="battle-arena-hand-head-block">` +
      `<span class="battle-dbg-hand-label battle-arena-hand-head">${escapeHtml(tt('battle_hand_head'))}</span>` +
      `<span class="battle-arena-hand-hint">${escapeHtml(tt('battle_hand_hint'))}</span>` +
      `</div>` +
      `${handRow}` +
      `</aside>` +
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
        const raw = global.AppState.battle;
        const st =
          mode === 'pvp'
            ? raw && raw.mode === 'pvp'
              ? pvpToArenaSt(raw)
              : null
            : raw && raw.mode === 'cpu'
              ? raw
              : null;
        if (!st || st.phase !== 'playing' || st.turn !== 'human') return;
        const i = parseInt(btn.getAttribute('data-dbg-hand') || '-1', 10);
        dbgSelectedHand = Number.isFinite(i) ? i : null;
        Battle.render();
      });
    });
    root.querySelectorAll('[data-dbg-cell]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const raw = global.AppState.battle;
        const st =
          mode === 'pvp'
            ? raw && raw.mode === 'pvp'
              ? pvpToArenaSt(raw)
              : null
            : raw && raw.mode === 'cpu'
              ? raw
              : null;
        if (!st || st.phase !== 'playing' || st.turn !== 'human') return;
        if (dbgSelectedHand == null) {
          if (typeof global.jpTcgbookShowError === 'function') {
            global.jpTcgbookShowError(tt('battle_err_pick_hand'));
          }
          return;
        }
        const cell = parseInt(btn.getAttribute('data-dbg-cell') || '0', 10);
        if (!Number.isFinite(cell) || cell < 1 || cell > 9) return;
        if (mode === 'pvp') {
          const b = global.AppState.battle;
          if (!b || b.mode !== 'pvp' || b.ended) return;
          if (b.session_id == null || b.turn_no == null) {
            if (typeof global.jpTcgbookShowError === 'function') {
              global.jpTcgbookShowError(tt('battle_err_bad_pvp_state'));
            }
            return;
          }
          api.battlePvpPlace({
            session_id: b.session_id,
            turn_no: b.turn_no,
            cell_index: cell,
            hand_index: dbgSelectedHand,
          });
        } else {
          api.battleDebugPlace(cell, dbgSelectedHand);
        }
        dbgSelectedHand = null;
      });
    });
    root.querySelector('.battle-arena-pvp-invalid-batch')?.addEventListener('click', () => {
      if (mode !== 'pvp') return;
      api.battlePvpTestInvalidBatch();
    });
    root.querySelector('.battle-arena-quit')?.addEventListener('click', () => {
      void (async () => {
        const rawBattle = global.AppState.battle;
        /* Finish 済みだとサーバーはセッション破棄済み → battlePvpLeave は OnPlayerLeave が即 return し NUI が残る */
        if (
          mode === 'pvp' &&
          rawBattle &&
          rawBattle.mode === 'pvp' &&
          rawBattle.ended === true
        ) {
          global.AppState.battle = null;
          const bv = global.AppState.battleVirtual || {};
          bv.connectedPeerId = null;
          bv.isCaller = null;
          bv.matchPrepLabel = '';
          Battle.render();
          return;
        }
        const fn = global.jpTcgbookConfirmIfVirtualBattleAsync;
        const msg =
          mode === 'pvp' ? tt('battle_confirm_resign_pvp') : tt('battle_confirm_quit_cpu');
        if (typeof fn === 'function' && !(await fn(msg))) return;
        if (mode === 'pvp') {
          api.battlePvpLeave();
        } else {
          api.battleDebugLeave();
        }
      })();
    });
    root.querySelector('.battle-pvp-result-dismiss')?.addEventListener('click', () => {
      global.AppState.battle = null;
      const bv = global.AppState.battleVirtual || {};
      bv.connectedPeerId = null;
      bv.isCaller = null;
      bv.matchPrepLabel = '';
      Battle.render();
    });
    applyDbgSlotMaxHighlights(root);
  }

  /** @returns {{ st: object, mode: 'cpu'|'pvp' } | null} */
  function getArenaView() {
    const b = global.AppState.battle;
    if (!b) return null;
    if (b.mode === 'cpu') return { st: b, mode: 'cpu' };
    if (b.mode === 'pvp') return { st: pvpToArenaSt(b), mode: 'pvp' };
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
          global.jpTcgbookShowError(tt('battle_err_peer_id'));
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
          ? tt('battle_leave_solo_confirm')
          : tt('battle_leave_virtual_confirm');
        if (typeof fn === 'function' && !(await fn(msg))) {
          return;
        }
        api.battleVirtualLeave();
      })();
    });

    root.querySelector('.battle-practice-start-cpu')?.addEventListener('click', (ev) => {
      const btn = ev.currentTarget;
      if (btn && 'disabled' in btn && btn.disabled) return;
      api.battleDebugStartCpu();
    });

    root.querySelector('#battleDbgLobbyToggle')?.addEventListener('change', (e) => {
      const t = e.target;
      global.AppState.battleCpuLobby = global.AppState.battleCpuLobby || {};
      global.AppState.battleCpuLobby.debugLobbyOpen = !!(t && t.checked);
      Battle.render();
    });
    root.querySelector('.battle-dbg-lookup-btn')?.addEventListener('click', () => {
      const inp = root.querySelector('#battleDbgLookupInput');
      const raw = inp && 'value' in inp ? inp.value : '';
      const tid = parseInt(String(raw).trim(), 10);
      if (!Number.isFinite(tid) || tid < 1) {
        if (typeof global.jpTcgbookShowError === 'function') {
          global.jpTcgbookShowError(tt('battle_err_lookup_id'));
        }
        return;
      }
      api.battleDebugLookupId(tid);
    });
    root.querySelector('.battle-pvp-start-solo')?.addEventListener('click', () => {
      api.battlePvpStartSolo();
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

  function dbgLocalizedCardName(c) {
    if (!c) return '';
    if (!CU || typeof CU.getLocalizedCardName !== 'function') return String(c.name || c.card_id || '');
    const id = c.card_id;
    const cm =
      global.AppState && Array.isArray(global.AppState.cardsMaster) ? global.AppState.cardsMaster : [];
    const m = cm.find((row) => row && row.card_id === id);
    const merged = m ? Object.assign({}, m, c) : c;
    return CU.getLocalizedCardName(merged) || String(c.card_id || '');
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
          if (typeof global.applyMarqueeIfOverflow === 'function') {
            global.applyMarqueeIfOverflow(arenaRoot);
          }
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
          `<p class="battle-hint">${escapeHtml(tt('battle_fullscreen_hint'))}</p>` +
          '</section>';
        return;
      }

      let html = '';
      html += renderReadinessSection(activeId, detail, false);
      html += renderPracticeCpuSection(activeId, detail, bv);
      if (allowDebugBattleUi() && bv.connectedPeerId == null && !bv.soloWireTest) {
        html += renderDebugLobbySection(global.AppState.battleCpuLobby || {});
      }
      html += renderLobbySection(bv);
      html +=
        `<p class="battle-next footnote">${escapeHtml(tt('battle_footer_long'))}</p>`;

      root.innerHTML = html;
      bindSectionHandlers(root);
    },
  };

  global.Battle = Battle;
})(window);

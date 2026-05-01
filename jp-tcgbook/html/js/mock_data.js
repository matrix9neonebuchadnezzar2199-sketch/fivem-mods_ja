/**
 * ブラウザ単体テスト用。
 * 本実装の shared/cards.lua とは別物（UI確認用・件数多め）。
 * FiveM では IS_FIVEM=true のためこのファイルはモック送信のみ初期化。
 */
(function (global) {
  const MAX_DECKS = 10;
  const DECK_SIZE = 10;
  const MAX_SHITEI = 2;
  const LIMIT_SHITEI_SAME = 1;
  const LIMIT_FREE_SAME = 2;

  /** 所持モックのベース47枚（デッキインデックスと整合） */
  const RANK_ORDER_FIRST = [
    ...Array(2).fill('UR'),
    ...Array(3).fill('SS'),
    ...Array(6).fill('S'),
    ...Array(8).fill('A'),
    ...Array(14).fill('B'),
    ...Array(14).fill('C'),
  ];

  /** 図鑑120枚に足す73枚分のランク配分 */
  const RANK_ORDER_EXTRA = [
    ...Array(2).fill('UR'),
    ...Array(5).fill('SS'),
    ...Array(14).fill('S'),
    ...Array(20).fill('A'),
    ...Array(16).fill('B'),
    ...Array(16).fill('C'),
  ];

  function statsForRank(rank, idx) {
    const base =
      rank === 'UR'
        ? [9, 9, 8, 8]
        : rank === 'SS'
          ? [8, 7, 7, 7]
          : rank === 'S'
            ? [7, 6, 6, 6]
            : rank === 'A'
              ? [6, 5, 5, 5]
              : rank === 'B'
                ? [5, 4, 4, 4]
                : [4, 3, 3, 3];
    const rot = idx % 4;
    return {
      stat_top: base[rot % 4],
      stat_right: base[(rot + 1) % 4],
      stat_bottom: base[(rot + 2) % 4],
      stat_left: base[(rot + 3) % 4],
    };
  }

  /** @type {{ card_id: string, name: string, rank: string, type: string, stat_top: number, stat_right: number, stat_bottom: number, stat_left: number, image_path: string, description: string, no: number }[]} */
  const masterBuild = [];

  RANK_ORDER_FIRST.forEach((rank, i) => {
    const type = rank === 'UR' || rank === 'SS' ? 'shitei' : 'free';
    const idNum = i + 1;
    const st = statsForRank(rank, i);
    masterBuild.push({
      card_id: `mock_${rank}_${String(idNum).padStart(3, '0')}`,
      name: `モック ${rank}-${idNum}`,
      rank,
      type,
      ...st,
      image_path: '',
      description: `${rank}ランクのダミーカードです`,
      no: idNum,
    });
  });

  RANK_ORDER_EXTRA.forEach((rank, j) => {
    const i = 47 + j;
    const type = rank === 'UR' || rank === 'SS' ? 'shitei' : 'free';
    const st = statsForRank(rank, i);
    masterBuild.push({
      card_id: `mock_CAT_${String(i + 1).padStart(3, '0')}`,
      name: `図鑑ダミー ${i + 1} (${rank})`,
      rank,
      type,
      ...st,
      image_path: '',
      description: `未所持想定の ${rank} カード（モック ${i + 1}）`,
      no: i + 1,
    });
  });

  const MOCK_CARDS_MASTER = masterBuild;
  const masterById = new Map(MOCK_CARDS_MASTER.map((m) => [m.card_id, m]));

  const citizenid = 'license:xxxxxxxxxxxxxxxx';

  /** 所持行（最初の47種のみ・ユニーク47） */
  const cards = masterBuild.slice(0, 47).map((m, i) => ({
    instance_id: i + 1,
    citizenid,
    card_id: m.card_id,
    obtained_at: `2026-01-${String((i % 28) + 1).padStart(2, '0')} ${String(10 + (i % 8)).padStart(2, '0')}:00:00`,
    locked: false,
    name: m.name,
    rank: m.rank,
    type: m.type,
    stat_top: m.stat_top,
    stat_right: m.stat_right,
    stat_bottom: m.stat_bottom,
    stat_left: m.stat_left,
    image_path: m.image_path,
    description: m.description,
    no: m.no,
  }));

  const deckSummaries = [
    { id: 1, citizenid, name: 'マイデッキ', is_active: true },
    { id: 2, citizenid, name: 'サブ・フル', is_active: false },
    { id: 3, citizenid, name: '未完成（5枚）', is_active: false },
  ];

  function cardPayload(m) {
    return {
      card_id: m.card_id,
      name: m.name,
      rank: m.rank,
      type: m.type,
      stat_top: m.stat_top,
      stat_right: m.stat_right,
      stat_bottom: m.stat_bottom,
      stat_left: m.stat_left,
      image_path: m.image_path,
      description: m.description,
      no: m.no,
    };
  }

  function cloneCardsMaster() {
    return MOCK_CARDS_MASTER.map((m) => ({ ...m }));
  }

  function getSlotRow(slots, idx1) {
    if (!Array.isArray(slots)) return null;
    const hit = slots.find((s) => Number(s.slot_index) === idx1);
    return hit || slots[idx1 - 1] || null;
  }

  function countFilledSlots(slots) {
    let n = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlotRow(slots, i);
      if (sl && sl.card) n++;
    }
    return n;
  }

  function deckPowerFromSlots(slots) {
    let p = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlotRow(slots, i);
      if (!sl || !sl.card) continue;
      const c = sl.card;
      p += Math.max(
        Number(c.stat_top),
        Number(c.stat_right),
        Number(c.stat_bottom),
        Number(c.stat_left),
      );
    }
    return p;
  }

  function countShiteiSlots(slots) {
    let n = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlotRow(slots, i);
      if (sl && sl.card && sl.card.type === 'shitei') n++;
    }
    return n;
  }

  function countInDeckSlots(slots, cardId) {
    let n = 0;
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlotRow(slots, i);
      if (sl && sl.card && sl.card.card_id === cardId) n++;
    }
    return n;
  }

  function ownedCountCard(cardId) {
    return MOCK_DATA.cards.filter((c) => c.card_id === cardId).length;
  }

  /**
   * @param {number} deckId
   * @param {number[]} cardIndices MOCK_CARDS_MASTER のインデックス（0-based）最大10個
   */
  function buildDeckDetail(deckId, cardIndices) {
    const summary = deckSummaries.find((d) => d.id === deckId);
    const slots = [];
    for (let i = 1; i <= DECK_SIZE; i++) {
      const mi = cardIndices[i - 1];
      const m = mi !== undefined ? MOCK_CARDS_MASTER[mi] : null;
      slots.push({
        slot_index: i,
        card: m ? cardPayload(m) : null,
      });
    }
    return {
      id: deckId,
      citizenid,
      name: summary ? summary.name : 'unknown',
      is_active: summary ? !!summary.is_active : false,
      created_at: '2026-01-01',
      updated_at: '2026-01-01',
      slots,
    };
  }

  /** デッキ編成: 1=10枚, 2=10枚, 3=5枚 */
  const deckComposition = {
    1: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    2: [10, 11, 12, 13, 14, 15, 16, 17, 18, 19],
    3: [20, 21, 22, 23, 24],
  };

  const MOCK_DATA = {
    player: {
      citizenid,
      initialized: true,
      rating: 1620,
      wins: 3,
      losses: 2,
      draws: 0,
    },
    cards,
    cardsMaster: MOCK_CARDS_MASTER,
    decks: deckSummaries,
    /** @type {Record<number, ReturnType<typeof buildDeckDetail>>} */
    deckDetails: {
      1: buildDeckDetail(1, deckComposition[1]),
      2: buildDeckDetail(2, deckComposition[2]),
      3: buildDeckDetail(3, deckComposition[3]),
    },
  };

  function syncDeckSummaryMeta() {
    MOCK_DATA.decks.forEach((d) => {
      const det = MOCK_DATA.deckDetails[d.id];
      if (!det || !det.slots) return;
      d.card_count = countFilledSlots(det.slots);
      d.power = deckPowerFromSlots(det.slots);
    });
  }

  syncDeckSummaryMeta();

  /** 対戦ロビー（ブラウザ単体：待受→番号入力で接続デモ） */
  let mockBattleWaiting = false;
  /** battleSoloVirtualWireTest 中（1人往復デモ） */
  let mockSoloWireTest = false;

  /** デバッグ CPU 対戦（ブラウザ単体・サーバー battle_debug と同形の簡易状態） */
  const MOCK_HAND_SIZE = 5;

  /** @type {null | { board: Record<number, { owner: string, card: object }|undefined>, human_hand: object[], cpu_hand: object[], turn: string, phase: string, first_player: string, scores?: object, winner?: string, log: string[] }} */
  let mockDbgCpuState = null;

  function mockDbgShuffleInPlace(arr) {
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [arr[i], arr[j]] = [arr[j], arr[i]];
    }
  }

  function mockDbgIdxToRc(idx) {
    const z = idx - 1;
    return [Math.floor(z / 3), z % 3];
  }

  function mockDbgRcToIdx(r, c) {
    return r * 3 + c + 1;
  }

  function mockDbgApplyCaptures(st, idx, owner, card) {
    const [r, c] = mockDbgIdxToRc(idx);
    const opp = owner === 'human' ? 'cpu' : 'human';
    const checks = [
      { nr: r - 1, nc: c, my: Number(card.stat_top), oppKey: 'stat_bottom' },
      { nr: r + 1, nc: c, my: Number(card.stat_bottom), oppKey: 'stat_top' },
      { nr: r, nc: c - 1, my: Number(card.stat_left), oppKey: 'stat_right' },
      { nr: r, nc: c + 1, my: Number(card.stat_right), oppKey: 'stat_left' },
    ];
    for (const ch of checks) {
      if (ch.nr < 0 || ch.nr > 2 || ch.nc < 0 || ch.nc > 2) continue;
      const ni = mockDbgRcToIdx(ch.nr, ch.nc);
      const cell = st.board[ni];
      if (cell && cell.owner === opp) {
        const ostat = Number(cell.card[ch.oppKey]) || 0;
        if (ch.my > ostat) cell.owner = owner;
      }
    }
  }

  function mockDbgBoardFull(st) {
    for (let i = 1; i <= 9; i++) {
      if (st.board[i] == null) return false;
    }
    return true;
  }

  function mockDbgScoreGame(st) {
    let humBoard = 0;
    let cpuBoard = 0;
    for (let i = 1; i <= 9; i++) {
      const cell = st.board[i];
      if (cell) {
        if (cell.owner === 'human') humBoard++;
        else cpuBoard++;
      }
    }
    const humHand = (st.human_hand || []).length;
    const cpuHand = (st.cpu_hand || []).length;
    return [humBoard + humHand, cpuBoard + cpuHand];
  }

  function mockDbgFinalizeIfEnded(st) {
    if (!mockDbgBoardFull(st)) return false;
    st.phase = 'ended';
    const [hs, cs] = mockDbgScoreGame(st);
    st.scores = { human: hs, cpu: cs };
    if (hs > cs) st.winner = 'human';
    else if (cs > hs) st.winner = 'cpu';
    else st.winner = 'draw';
    return true;
  }

  function mockDbgCpuRandomPlace(st) {
    const empties = [];
    for (let i = 1; i <= 9; i++) {
      if (st.board[i] == null) empties.push(i);
    }
    if (empties.length === 0 || !(st.cpu_hand || []).length) return false;
    const idx = empties[Math.floor(Math.random() * empties.length)];
    const hi = Math.floor(Math.random() * st.cpu_hand.length);
    const card = st.cpu_hand.splice(hi, 1)[0];
    st.board[idx] = { owner: 'cpu', card };
    mockDbgApplyCaptures(st, idx, 'cpu', card);
    st.turn = 'human';
    mockDbgFinalizeIfEnded(st);
    return true;
  }

  function mockDbgBuildClientPayload(st) {
    const board = {};
    for (let i = 1; i <= 9; i++) {
      const cell = st.board[i];
      if (cell) board[String(i)] = { owner: cell.owner, card: cell.card };
    }
    return {
      phase: st.phase,
      turn: st.turn,
      board,
      human_hand: st.human_hand,
      cpu_hand_count: (st.cpu_hand || []).length,
      scores: st.scores,
      winner: st.winner,
      first_player: st.first_player,
      log: st.log || [],
    };
  }

  function mockDbgPushState() {
    if (!mockDbgCpuState) return;
    global.postMessage({ action: 'battleDebugState', payload: mockDbgBuildClientPayload(mockDbgCpuState) }, '*');
  }

  /** ブラウザ単体: 擬似 PvP（相手は簡易 AI・101 が自分固定） */
  let mockPvpSession = null;

  function mockPvpApplyCaptures(board, idx, owner, card) {
    const [r, c] = mockDbgIdxToRc(idx);
    const checks = [
      { nr: r - 1, nc: c, my: Number(card.stat_top), oppKey: 'stat_bottom' },
      { nr: r + 1, nc: c, my: Number(card.stat_bottom), oppKey: 'stat_top' },
      { nr: r, nc: c - 1, my: Number(card.stat_left), oppKey: 'stat_right' },
      { nr: r, nc: c + 1, my: Number(card.stat_right), oppKey: 'stat_left' },
    ];
    for (const ch of checks) {
      if (ch.nr < 0 || ch.nr > 2 || ch.nc < 0 || ch.nc > 2) continue;
      const ni = mockDbgRcToIdx(ch.nr, ch.nc);
      const cell = board[ni];
      if (cell && cell.owner !== owner) {
        const ostat = Number(cell.card[ch.oppKey]) || 0;
        if (ch.my > ostat) cell.owner = owner;
      }
    }
  }

  function mockPvpBoardFull(s) {
    for (let i = 1; i <= 9; i++) {
      if (!s.board[i]) return false;
    }
    return true;
  }

  function mockPvpScoreTotal(s, pid) {
    let n = 0;
    for (let i = 1; i <= 9; i++) {
      const c = s.board[i];
      if (c && c.owner === pid) n++;
    }
    return n + (s.hands[pid] || []).length;
  }

  function mockPvpBuildViewerPayload(viewer) {
    const s = mockPvpSession;
    const opp = viewer === s.me ? s.opp : s.me;
    const boardArr = [];
    for (let i = 1; i <= 9; i++) {
      const cell = s.board[i];
      if (!cell) boardArr.push(null);
      else {
        boardArr.push({
          card: { ...cell.card },
          owner_server_id: cell.owner,
          is_mine: cell.owner === viewer,
        });
      }
    }
    return {
      session_id: s.session_id,
      turn_no: s.turn_no,
      turn_server_id: s.turn,
      is_my_turn: s.turn === viewer,
      board: boardArr,
      my_hand: (s.hands[viewer] || []).map((c) => ({ ...c })),
      opponent_hand_count: (s.hands[opp] || []).length,
      opponent_server_id: opp,
    };
  }

  function mockPvpPushStarted() {
    if (!mockPvpSession) return;
    global.postMessage(
      { action: 'battlePvpStarted', payload: mockPvpBuildViewerPayload(mockPvpSession.me) },
      '*',
    );
  }

  function mockPvpPushState() {
    if (!mockPvpSession) return;
    global.postMessage(
      { action: 'battlePvpState', payload: mockPvpBuildViewerPayload(mockPvpSession.me) },
      '*',
    );
  }

  function mockPvpPushEnded(reason) {
    if (!mockPvpSession) return;
    const s = mockPvpSession;
    const me = s.me;
    const opp = s.opp;
    const myS = mockPvpScoreTotal(s, me);
    const opS = mockPvpScoreTotal(s, opp);
    let outcome;
    if (reason === 'normal') {
      if (myS > opS) outcome = 'win';
      else if (opS > myS) outcome = 'lose';
      else outcome = 'draw';
    } else {
      outcome = 'lose';
    }
    global.postMessage(
      {
        action: 'battlePvpEnded',
        payload: {
          session_id: s.session_id,
          reason,
          my_score: myS,
          opponent_score: opS,
          outcome,
          final_board: mockPvpBuildViewerPayload(me).board,
          my_hand_remaining: (s.hands[me] || []).length,
        },
      },
      '*',
    );
    mockPvpSession = null;
  }

  function mockPvpScheduleAi() {
    setTimeout(() => {
      if (!mockPvpSession) return;
      const s = mockPvpSession;
      if (s.turn === s.me) return;
      const pid = s.turn;
      const empties = [];
      for (let i = 1; i <= 9; i++) {
        if (!s.board[i]) empties.push(i);
      }
      const hh = s.hands[pid];
      if (!empties.length || !hh || !hh.length) return;
      const idx = empties[Math.floor(Math.random() * empties.length)];
      const hi = Math.floor(Math.random() * hh.length);
      const card = hh.splice(hi, 1)[0];
      s.board[idx] = { owner: pid, card };
      mockPvpApplyCaptures(s.board, idx, pid, card);
      s.turn_no += 1;
      s.turn = pid === s.me ? s.opp : s.me;
      if (mockPvpBoardFull(s)) {
        mockPvpPushEnded('normal');
        return;
      }
      mockPvpPushState();
      if (mockPvpSession && mockPvpSession.turn === mockPvpSession.opp) {
        mockPvpScheduleAi();
      }
    }, 500);
  }

  function mockPvpBootstrap(opponentId) {
    const me = 101;
    const opp = opponentId;
    const active = MOCK_DATA.decks.find((d) => d.is_active === true || d.is_active === 1);
    if (!active) return;
    const det = MOCK_DATA.deckDetails[active.id];
    if (!det || !det.slots) return;
    const deckCards = [];
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlotRow(det.slots, i);
      if (sl && sl.card && sl.card.card_id) deckCards.push({ ...sl.card });
    }
    if (deckCards.length < DECK_SIZE) return;
    mockDbgShuffleInPlace(deckCards);
    const myHand = deckCards.slice(0, MOCK_HAND_SIZE);
    const cpuPool = MOCK_CARDS_MASTER.map((m) => cardPayload(m));
    mockDbgShuffleInPlace(cpuPool);
    const oppHand = cpuPool.slice(0, MOCK_HAND_SIZE);
    const first = Math.random() < 0.5 ? me : opp;
    mockPvpSession = {
      session_id: `pvp_mock_${Date.now()}`,
      me,
      opp,
      board: {},
      hands: { [me]: myHand, [opp]: oppHand },
      turn: first,
      turn_no: 1,
    };
    setTimeout(() => {
      mockPvpPushStarted();
      mockPvpPushState();
      if (mockPvpSession && mockPvpSession.turn === mockPvpSession.opp) {
        mockPvpScheduleAi();
      }
    }, 80);
  }

  global.mockData = MOCK_DATA;

  const MOCK_ACTION_MAP = {
    openBook: 'bookData',
    selectDeck: 'deckSelected',
    addCardToDeck: 'deckUpdated',
    removeDeckCard: 'deckUpdated',
    createDeck: 'deckListUpdated',
    duplicateDeck: 'deckListUpdated',
    deleteDeck: 'deckListUpdated',
    renameDeck: 'deckListUpdated',
    setActiveDeck: 'deckListUpdated',
  };

  function fail(msg) {
    return { success: false, error: msg };
  }

  function cloneDeckDetail(id) {
    const raw = MOCK_DATA.deckDetails[id];
    if (!raw) return null;
    const o = JSON.parse(JSON.stringify(raw));
    const activeRow = MOCK_DATA.decks.find((d) => d.id === id);
    o.is_active = !!(activeRow && (activeRow.is_active === true || activeRow.is_active === 1));
    return o;
  }

  function okDeckList(extra) {
    const active = MOCK_DATA.decks.find((d) => d.is_active === true || d.is_active === 1);
    const activeDeck = active ? cloneDeckDetail(active.id) : null;
    const data = {
      decks: MOCK_DATA.decks.map((d) => ({ ...d })),
      activeDeck,
      cards: MOCK_DATA.cards.map((c) => ({ ...c })),
      cardsMaster: cloneCardsMaster(),
    };
    if (extra && typeof extra === 'object') {
      Object.assign(data, extra);
    }
    return {
      success: true,
      data,
    };
  }

  function parseDeckId(raw) {
    const n = Number(raw);
    return Number.isInteger(n) && n >= 1 ? n : null;
  }

  function parseCardId(raw) {
    if (raw == null) return null;
    const s = String(raw).trim();
    return s === '' ? null : s;
  }

  function parseDeckName(raw) {
    if (raw == null || typeof raw !== 'string') return null;
    const s = raw.trim();
    if (s.length < 1 || s.length > 64) return null;
    return s;
  }

  function findFirstEmptySlotIndex(slots) {
    for (let i = 1; i <= DECK_SIZE; i++) {
      const sl = getSlotRow(slots, i);
      if (sl && !sl.card) return i;
    }
    return null;
  }

  function canAddToDeck(deckId, cardId) {
    const master = masterById.get(cardId);
    if (!master) return { ok: false, error: '存在しないカードです' };

    const det = MOCK_DATA.deckDetails[deckId];
    if (!det) return { ok: false, error: 'デッキが見つかりません' };

    const slots = det.slots;
    const filled = countFilledSlots(slots);
    if (filled >= DECK_SIZE) return { ok: false, error: 'デッキが満杯です' };

    const owned = ownedCountCard(cardId);
    const inDeck = countInDeckSlots(slots, cardId);
    if (owned <= inDeck) return { ok: false, error: '所持枚数が不足しています' };

    const limitSame = master.type === 'shitei' ? LIMIT_SHITEI_SAME : LIMIT_FREE_SAME;
    if (inDeck >= limitSame) {
      return { ok: false, error: 'このカードは既に上限まで編成されています' };
    }

    const shiteiN = countShiteiSlots(slots);
    if (master.type === 'shitei' && shiteiN >= MAX_SHITEI) {
      return { ok: false, error: '指定カード上限です' };
    }

    return { ok: true };
  }

  function generateCopyName(baseName) {
    const nameSet = new Set(MOCK_DATA.decks.map((d) => d.name));
    let candidate = baseName + ' - Copy';
    if (!nameSet.has(candidate)) return candidate;
    let i = 1;
    while (nameSet.has(baseName + ' - Copy ' + i)) i++;
    return baseName + ' - Copy ' + i;
  }

  function nextDeckId() {
    return Math.max(0, ...MOCK_DATA.decks.map((d) => d.id)) + 1;
  }

  function emptyDeckDetail(id, name, isActive) {
    const slots = [];
    for (let i = 1; i <= DECK_SIZE; i++) {
      slots.push({ slot_index: i, card: null });
    }
    return {
      id,
      citizenid,
      name,
      is_active: !!isActive,
      created_at: '2026-01-01',
      updated_at: '2026-01-01',
      slots,
    };
  }

  const MOCK_HANDLERS = {
    openBook() {
      const ad = cloneDeckDetail(1);
      return {
        success: true,
        data: {
          player: { ...MOCK_DATA.player },
          cards: MOCK_DATA.cards.map((c) => ({ ...c })),
          decks: MOCK_DATA.decks.map((d) => ({ ...d })),
          cardsMaster: cloneCardsMaster(),
          activeDeck: ad,
          battleSession: null,
          battleCpuSession: mockDbgCpuState ? mockDbgBuildClientPayload(mockDbgCpuState) : null,
          battlePvpSession: null,
          ui: {
            autoSaveDebounceMs: 500,
            playerServerId: 101,
            allow_debug_battle: true,
            wire_log: true,
          },
        },
      };
    },

    selectDeck(data) {
      const id = parseDeckId(data && data.deck_id);
      if (!id) return fail('不正なデッキIDです');
      const detail = cloneDeckDetail(id);
      if (!detail) return fail('デッキが見つかりません');
      return { success: true, data: detail };
    },

    addCardToDeck(data) {
      const deckId = parseDeckId(data && data.deck_id);
      const cardId = parseCardId(data && data.card_id);
      if (!deckId) return fail('不正なデッキIDです');
      if (!cardId) return fail('不正なカードIDです');

      const check = canAddToDeck(deckId, cardId);
      if (!check.ok) return fail(check.error);

      const det = MOCK_DATA.deckDetails[deckId];
      const idx = findFirstEmptySlotIndex(det.slots);
      if (!idx) return fail('デッキが満杯です');

      const sl = getSlotRow(det.slots, idx);
      const m = masterById.get(cardId);
      if (!sl || !m) return fail('カードを追加できません');
      sl.card = cardPayload(m);
      syncDeckSummaryMeta();
      return { success: true, data: cloneDeckDetail(deckId) };
    },

    removeDeckCard(data) {
      const deckId = parseDeckId(data && data.deck_id);
      const slot = Number(data && data.slot);
      if (!deckId) return fail('不正なデッキIDです');
      if (!Number.isInteger(slot) || slot < 1 || slot > DECK_SIZE) {
        return fail('不正なスロットです（1〜10）');
      }

      const det = MOCK_DATA.deckDetails[deckId];
      if (!det) return fail('デッキが見つかりません');

      const sl = getSlotRow(det.slots, slot);
      if (!sl || !sl.card) return fail('空のスロットです');

      sl.card = null;
      syncDeckSummaryMeta();
      return { success: true, data: cloneDeckDetail(deckId) };
    },

    createDeck(data) {
      const name = parseDeckName(data && data.name);
      if (!name) return fail('デッキ名は1〜64文字で入力してください');
      if (MOCK_DATA.decks.length >= MAX_DECKS) {
        return fail('デッキ保有数が上限に達しています');
      }

      const newId = nextDeckId();
      MOCK_DATA.decks.push({
        id: newId,
        citizenid,
        name,
        is_active: false,
        card_count: 0,
        power: 0,
      });
      MOCK_DATA.deckDetails[newId] = emptyDeckDetail(newId, name, false);
      syncDeckSummaryMeta();
      return okDeckList({ createdDeckId: newId });
    },

    duplicateDeck(data) {
      const srcId = parseDeckId(data && data.deck_id);
      if (!srcId) return fail('不正なデッキIDです');
      if (MOCK_DATA.decks.length >= MAX_DECKS) {
        return fail('デッキ保有数が上限に達しています');
      }

      const src = MOCK_DATA.deckDetails[srcId];
      if (!src) return fail('デッキが見つかりません');

      const need = {};
      for (let i = 1; i <= DECK_SIZE; i++) {
        const sl = getSlotRow(src.slots, i);
        if (sl && sl.card) {
          const cid = sl.card.card_id;
          need[cid] = (need[cid] || 0) + 1;
        }
      }
      for (const cid of Object.keys(need)) {
        if (ownedCountCard(cid) < need[cid]) {
          return fail('所持枚数が不足しているためコピーできません');
        }
      }

      const newId = nextDeckId();
      const newName = generateCopyName(src.name);
      MOCK_DATA.decks.push({
        id: newId,
        citizenid,
        name: newName,
        is_active: false,
        card_count: 0,
        power: 0,
      });

      const copy = JSON.parse(JSON.stringify(src));
      copy.id = newId;
      copy.name = newName;
      copy.is_active = false;
      MOCK_DATA.deckDetails[newId] = copy;
      syncDeckSummaryMeta();
      return okDeckList({ createdDeckId: newId });
    },

    deleteDeck(data) {
      const id = parseDeckId(data && data.deck_id);
      if (!id) return fail('不正なデッキIDです');
      if (MOCK_DATA.decks.length <= 1) return fail('最後のデッキは削除できません');

      const idx = MOCK_DATA.decks.findIndex((d) => d.id === id);
      if (idx < 0) return fail('デッキが見つかりません');

      const wasActive = MOCK_DATA.decks[idx].is_active === true || MOCK_DATA.decks[idx].is_active === 1;
      MOCK_DATA.decks.splice(idx, 1);
      delete MOCK_DATA.deckDetails[id];

      if (wasActive && MOCK_DATA.decks.length) {
        const nextFull = MOCK_DATA.decks.find((d) => {
          const det = MOCK_DATA.deckDetails[d.id];
          return det && countFilledSlots(det.slots) === DECK_SIZE;
        });
        MOCK_DATA.decks.forEach((d) => {
          d.is_active = nextFull ? d.id === nextFull.id : false;
        });
        Object.keys(MOCK_DATA.deckDetails).forEach((k) => {
          const nid = Number(k);
          MOCK_DATA.deckDetails[nid].is_active = nextFull ? nid === nextFull.id : false;
        });
      }

      syncDeckSummaryMeta();
      return okDeckList();
    },

    renameDeck(data) {
      const deckId = parseDeckId(data && data.deck_id);
      const newName = parseDeckName(data && data.new_name);
      if (!deckId) return fail('不正なデッキIDです');
      if (!newName) return fail('デッキ名は1〜64文字で入力してください');

      const row = MOCK_DATA.decks.find((d) => d.id === deckId);
      if (!row) return fail('デッキが見つかりません');

      const dup = MOCK_DATA.decks.find((d) => d.id !== deckId && d.name === newName);
      if (dup) return fail('同じデッキ名が既に存在します');

      row.name = newName;
      const det = MOCK_DATA.deckDetails[deckId];
      if (det) det.name = newName;
      syncDeckSummaryMeta();
      return okDeckList();
    },

    setActiveDeck(data) {
      const id = parseDeckId(data && data.deck_id);
      if (!id) return fail('不正なデッキIDです');

      const det = MOCK_DATA.deckDetails[id];
      if (!det) return fail('デッキが見つかりません');
      if (countFilledSlots(det.slots) < DECK_SIZE) {
        return fail('10枚揃ったデッキのみ使用設定できます');
      }

      MOCK_DATA.decks.forEach((d) => {
        d.is_active = d.id === id;
      });
      Object.keys(MOCK_DATA.deckDetails).forEach((k) => {
        const nid = Number(k);
        MOCK_DATA.deckDetails[nid].is_active = nid === id;
      });
      syncDeckSummaryMeta();
      return okDeckList();
    },

    battleSetWaiting(data) {
      if (mockSoloWireTest) {
        setTimeout(() => {
          global.postMessage(
            {
              action: 'battleLobbyError',
              payload: { error: 'ソロ検証接続中は待受を切り替えられません（先に「切断する」）' },
            },
            '*',
          );
        }, 15);
        return { success: true };
      }
      mockBattleWaiting = !!(data && data.waiting);
      setTimeout(() => {
        global.postMessage({ action: 'battleWaitingAck', payload: { waiting: mockBattleWaiting } }, '*');
      }, 25);
      return { success: true };
    },

    battleCallById(data) {
      if (mockSoloWireTest) {
        const r = fail('ソロ検証接続中は呼び出せません（先に「切断する」）');
        setTimeout(() => {
          global.postMessage({ action: 'battleLobbyError', payload: { error: r.error } }, '*');
        }, 15);
        return r;
      }
      const tid = Number(data && data.target_server_id);
      if (!Number.isFinite(tid) || tid < 1) {
        const r = fail('相手の番号（整数）を入力してください');
        setTimeout(() => {
          global.postMessage({ action: 'battleLobbyError', payload: { error: r.error } }, '*');
        }, 15);
        return r;
      }
      if (!mockBattleWaiting) {
        const r = fail('先に「招待待機を開始」してください（モックは1タブ内デモ）');
        setTimeout(() => {
          global.postMessage({ action: 'battleLobbyError', payload: { error: r.error } }, '*');
        }, 15);
        return r;
      }
      mockBattleWaiting = false;
      setTimeout(() => {
        global.postMessage({
          action: 'virtualBattleMatched',
          payload: { peer_server_id: tid, is_caller: true, is_pvp: true },
        }, '*');
        mockPvpBootstrap(tid);
      }, 35);
      return { success: true };
    },

    battleVirtualLeave() {
      mockSoloWireTest = false;
      mockBattleWaiting = false;
      if (mockPvpSession) {
        mockPvpPushEnded('peer_left');
      }
      if (mockDbgCpuState) {
        mockDbgCpuState = null;
        setTimeout(() => {
          global.postMessage({ action: 'battleDebugEnded', payload: {} }, '*');
        }, 12);
      }
      setTimeout(() => {
        global.postMessage({ action: 'virtualBattleEnded', payload: {} }, '*');
      }, 20);
      return { success: true };
    },

    battleSoloVirtualWireTest() {
      if (mockDbgCpuState) {
        setTimeout(() => {
          global.postMessage(
            { action: 'battleLobbyError', payload: { error: 'デバッグ対戦中は使えません（先に終了）' } },
            '*',
          );
        }, 15);
        return { success: true };
      }
      mockBattleWaiting = false;
      mockSoloWireTest = true;
      setTimeout(() => {
        global.postMessage(
          {
            action: 'virtualBattleMatched',
            payload: {
              peer_server_id: null,
              is_caller: true,
              solo_wire_test: true,
              peer_label: 'ソロ検証（2人目のクライアントなし・モック）',
            },
          },
          '*',
        );
      }, 30);
      return { success: true };
    },

    battleDebugLookupId(data) {
      const tid = Number(data && data.target_server_id);
      if (!Number.isFinite(tid) || tid < 1 || Math.floor(tid) !== tid) {
        global.postMessage({
          action: 'battleDebugLookupAck',
          payload: { ok: false, error: '検索するサーバーID（正の整数）を入力してください' },
        }, '*');
        return;
      }
      global.postMessage(
        {
          action: 'battleDebugLookupAck',
          payload: {
            ok: true,
            target_server_id: tid,
            display_name: `検証用: サーバーID ${tid}（応答のみ・実プレイヤーではありません）`,
          },
        },
        '*',
      );
    },

    battleDebugStartCpu() {
      if (mockSoloWireTest) {
        global.postMessage(
          {
            action: 'battleLobbyError',
            payload: { error: 'ソロ検証接続中です。先に仮想対戦を切断してください。' },
          },
          '*',
        );
        return;
      }
      mockPvpSession = null;
      const active = MOCK_DATA.decks.find((d) => d.is_active === true || d.is_active === 1);
      if (!active) {
        global.postMessage({ action: 'battleLobbyError', payload: { error: '使用デッキがありません' } }, '*');
        return;
      }
      const det = MOCK_DATA.deckDetails[active.id];
      if (!det || !det.slots) {
        global.postMessage({ action: 'battleLobbyError', payload: { error: 'デッキ取得失敗' } }, '*');
        return;
      }
      const deckCards = [];
      for (let i = 1; i <= DECK_SIZE; i++) {
        const sl = getSlotRow(det.slots, i);
        if (sl && sl.card && sl.card.card_id) {
          deckCards.push({ ...sl.card });
        }
      }
      if (deckCards.length < DECK_SIZE) {
        global.postMessage(
          {
            action: 'battleLobbyError',
            payload: { error: `デッキが ${DECK_SIZE} 枚未満です（要 ${DECK_SIZE} 枚）` },
          },
          '*',
        );
        return;
      }
      mockDbgShuffleInPlace(deckCards);
      const human_hand = deckCards.slice(0, MOCK_HAND_SIZE);

      const cpuPool = MOCK_CARDS_MASTER.map((m) => cardPayload(m));
      mockDbgShuffleInPlace(cpuPool);
      const cpu_hand = cpuPool.slice(0, MOCK_HAND_SIZE);

      const first = Math.random() < 0.5 ? 'human' : 'cpu';
      mockDbgCpuState = {
        board: {},
        human_hand,
        cpu_hand,
        turn: first,
        phase: 'playing',
        first_player: first,
        scores: null,
        winner: null,
        log: [first === 'human' ? '先攻: あなた' : '先攻: CPU'],
      };

      if (first === 'cpu') {
        mockDbgCpuRandomPlace(mockDbgCpuState);
        mockDbgCpuState.log.push('CPU がランダムに配置しました');
      }

      mockDbgPushState();
      global.postMessage(
        {
          action: 'virtualBattleMatched',
          payload: { peer_server_id: null, is_cpu: true, is_caller: true },
        },
        '*',
      );
    },

    battleDebugPlace(data) {
      if (!mockDbgCpuState || mockDbgCpuState.phase !== 'playing') {
        global.postMessage({ action: 'battleLobbyError', payload: { error: '対局中ではありません' } }, '*');
        return;
      }
      if (mockDbgCpuState.turn !== 'human') {
        global.postMessage({ action: 'battleLobbyError', payload: { error: '相手のターンです' } }, '*');
        return;
      }
      const cellIdx = Number(data && data.cell_index);
      let handIdx = Number(data && data.hand_index);
      if (!Number.isFinite(cellIdx) || cellIdx < 1 || cellIdx > 9 || Math.floor(cellIdx) !== cellIdx) {
        global.postMessage({ action: 'battleLobbyError', payload: { error: 'マスが不正です（1〜9）' } }, '*');
        return;
      }
      handIdx = Number.isFinite(handIdx) ? Math.floor(handIdx) : -1;
      if (handIdx < 0 || handIdx >= mockDbgCpuState.human_hand.length) {
        global.postMessage({
          action: 'battleLobbyError',
          payload: { error: '手札インデックスが不正です（0 から）' },
        }, '*');
        return;
      }
      if (mockDbgCpuState.board[cellIdx] != null) {
        global.postMessage({ action: 'battleLobbyError', payload: { error: 'そのマスは埋まっています' } }, '*');
        return;
      }

      const card = mockDbgCpuState.human_hand.splice(handIdx, 1)[0];
      mockDbgCpuState.board[cellIdx] = { owner: 'human', card };
      mockDbgApplyCaptures(mockDbgCpuState, cellIdx, 'human', card);
      mockDbgCpuState.log.push(`あなた: マス ${cellIdx} に配置`);

      if (mockDbgFinalizeIfEnded(mockDbgCpuState)) {
        mockDbgCpuState.log.push(
          `終了: あなた ${mockDbgCpuState.scores.human} vs CPU ${mockDbgCpuState.scores.cpu}`,
        );
        mockDbgPushState();
        return;
      }

      mockDbgCpuState.turn = 'cpu';
      mockDbgCpuRandomPlace(mockDbgCpuState);
      if (mockDbgCpuState.phase === 'playing') {
        mockDbgCpuState.log.push('CPU がランダムに配置しました');
      } else {
        mockDbgCpuState.log.push(
          `終了: あなた ${mockDbgCpuState.scores.human} vs CPU ${mockDbgCpuState.scores.cpu}`,
        );
      }
      mockDbgPushState();
    },

    battleDebugLeave() {
      mockDbgCpuState = null;
      global.postMessage({ action: 'battleDebugEnded', payload: {} }, '*');
    },

    battlePvpPlace(data) {
      const pushErr = (reason) => {
        global.postMessage({ action: 'battlePvpError', payload: { reason } }, '*');
      };
      if (!mockPvpSession) {
        pushErr('session_not_found');
        return;
      }
      const d = data || {};
      const s = mockPvpSession;
      if (d.session_id !== s.session_id) {
        pushErr('session_not_found');
        return;
      }
      if (s.turn !== s.me) {
        pushErr('not_your_turn');
        return;
      }
      if (Number(d.turn_no) !== s.turn_no) {
        pushErr('turn_no_mismatch');
        return;
      }
      const cellIdx = Number(d.cell_index);
      if (!Number.isFinite(cellIdx) || cellIdx < 1 || cellIdx > 9 || Math.floor(cellIdx) !== cellIdx) {
        pushErr('invalid_cell');
        return;
      }
      if (s.board[cellIdx] != null) {
        pushErr('cell_occupied');
        return;
      }
      let handIdx = Number(d.hand_index);
      handIdx = Number.isFinite(handIdx) ? Math.floor(handIdx) : -1;
      if (handIdx < 0 || handIdx > 4) {
        pushErr('invalid_hand_index');
        return;
      }
      const hh = s.hands[s.me];
      if (!hh || handIdx >= hh.length) {
        pushErr('hand_card_missing');
        return;
      }
      const card = hh.splice(handIdx, 1)[0];
      s.board[cellIdx] = { owner: s.me, card };
      mockPvpApplyCaptures(s.board, cellIdx, s.me, card);
      s.turn_no += 1;
      s.turn = s.opp;
      if (mockPvpBoardFull(s)) {
        mockPvpPushEnded('normal');
        return;
      }
      mockPvpPushState();
      if (mockPvpSession && mockPvpSession.turn === mockPvpSession.opp) {
        mockPvpScheduleAi();
      }
    },

    battlePvpLeave() {
      if (!mockPvpSession) return;
      mockPvpPushEnded('voluntary_leave');
    },

    battlePvpRequestState(data) {
      const pushErr = (reason) => {
        global.postMessage({ action: 'battlePvpError', payload: { reason } }, '*');
      };
      if (!mockPvpSession) {
        pushErr('session_not_found');
        return;
      }
      const sid = data && data.session_id;
      if (sid !== mockPvpSession.session_id) {
        pushErr('session_not_found');
        return;
      }
      mockPvpPushState();
    },
  };

  global.mockDispatchServerEvent = function (eventName, data) {
    const dbgEvents = {
      battleDebugLookupId: true,
      battleDebugStartCpu: true,
      battleDebugPlace: true,
      battleDebugLeave: true,
      battlePvpPlace: true,
      battlePvpLeave: true,
      battlePvpRequestState: true,
    };
    if (dbgEvents[eventName]) {
      setTimeout(() => {
        const fn = MOCK_HANDLERS[eventName];
        if (fn) fn(data || {});
      }, 40);
      return;
    }

    const handler = MOCK_HANDLERS[eventName];
    if (!handler) return;

    setTimeout(() => {
      const result = handler(data || {});
      const action = MOCK_ACTION_MAP[eventName];
      if (action) {
        global.postMessage({ action, payload: result }, '*');
      }
    }, 50);
  };

  if (!global.NUI.IS_FIVEM) {
    const rankTally = MOCK_CARDS_MASTER.reduce((acc, m) => {
      acc[m.rank] = (acc[m.rank] || 0) + 1;
      return acc;
    }, {});
    console.info(
      '[jp-tcgbook] mockData:',
      MOCK_CARDS_MASTER.length,
      'マスタ / 所持インスタンス',
      MOCK_DATA.cards.length,
      '（ブラウザモード）。ランク内訳:',
      rankTally,
    );
  }
})(window);

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
      return {
        success: true,
        data: {
          player: { ...MOCK_DATA.player },
          cards: MOCK_DATA.cards.map((c) => ({ ...c })),
          decks: MOCK_DATA.decks.map((d) => ({ ...d })),
          cardsMaster: cloneCardsMaster(),
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
  };

  global.mockDispatchServerEvent = function (eventName, data) {
    const handler = MOCK_HANDLERS[eventName];
    const action = MOCK_ACTION_MAP[eventName];
    if (!handler || !action) return;

    setTimeout(() => {
      const result = handler(data || {});
      global.postMessage({ action, payload: result }, '*');
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

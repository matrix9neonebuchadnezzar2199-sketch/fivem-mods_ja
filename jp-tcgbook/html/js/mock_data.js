/**
 * ブラウザ単体テスト用。
 * 本実装の shared/cards.lua とは別物（UI確認用・件数多め）。
 * FiveM では IS_FIVEM=true のためこのファイルはモック送信のみ初期化。
 */
(function (global) {
  const RANK_ORDER = [
    ...Array(2).fill('UR'),
    ...Array(3).fill('SS'),
    ...Array(6).fill('S'),
    ...Array(8).fill('A'),
    ...Array(14).fill('B'),
    ...Array(14).fill('C'),
  ];

  const EMOJI = ['🐉', '🦅', '🛡', '⚔', '🔥', '❄', '⚡', '🌙', '⭐', '🎯'];

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
  const master = [];

  RANK_ORDER.forEach((rank, i) => {
    const type = rank === 'UR' || rank === 'SS' ? 'shitei' : 'free';
    const idNum = i + 1;
    const st = statsForRank(rank, i);
    master.push({
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

  const citizenid = 'license:xxxxxxxxxxxxxxxx';

  /** 所持行（サーバー GetPlayerCards 相当） */
  const cards = master.map((m, i) => ({
    instance_id: i + 1,
    citizenid,
    card_id: m.card_id,
    obtained_at: '2026-01-01 12:00:00',
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

  /**
   * @param {number} deckId
   * @param {number[]} cardIndices master のインデックス（0-based）最大10個
   */
  function buildDeckDetail(deckId, cardIndices) {
    const summary = deckSummaries.find((d) => d.id === deckId);
    const slots = [];
    for (let i = 1; i <= 10; i++) {
      const mi = cardIndices[i - 1];
      const m = mi !== undefined ? master[mi] : null;
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
    decks: deckSummaries,
    /** @type {Record<number, ReturnType<typeof buildDeckDetail>>} */
    deckDetails: {
      1: buildDeckDetail(1, deckComposition[1]),
      2: buildDeckDetail(2, deckComposition[2]),
      3: buildDeckDetail(3, deckComposition[3]),
    },
  };

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

  function okDeckList() {
    const active = MOCK_DATA.decks.find((d) => d.is_active === true || d.is_active === 1);
    const activeDeck = active ? cloneDeckDetail(active.id) : null;
    return {
      success: true,
      data: {
        decks: MOCK_DATA.decks.map((d) => ({ ...d })),
        activeDeck,
        cards: MOCK_DATA.cards.map((c) => ({ ...c })),
      },
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
        },
      };
    },

    selectDeck(data) {
      const id = Number(data && data.deck_id);
      if (!Number.isInteger(id) || id < 1) return fail('不正なデッキIDです');
      const detail = cloneDeckDetail(id);
      if (!detail) return fail('デッキが見つかりません');
      return { success: true, data: detail };
    },

    addCardToDeck(data) {
      const id = Number(data && data.deck_id);
      return fail(`モック: addCardToDeck deck=${id}（フェーズ1-6-3で検証）`);
    },

    removeDeckCard(data) {
      const id = Number(data && data.deck_id);
      return fail(`モック: removeDeckCard deck=${id}（フェーズ1-6-3で検証）`);
    },

    createDeck() {
      return fail('モック: createDeck（フェーズ1-6-3で検証）');
    },

    duplicateDeck() {
      return fail('モック: duplicateDeck（フェーズ1-6-3で検証）');
    },

    deleteDeck() {
      return fail('モック: deleteDeck（フェーズ1-6-3で検証）');
    },

    renameDeck() {
      return fail('モック: renameDeck（フェーズ1-6-3で検証）');
    },

    setActiveDeck(data) {
      const id = Number(data && data.deck_id);
      if (!Number.isInteger(id) || id < 1) return fail('不正なデッキIDです');
      MOCK_DATA.decks.forEach((d) => {
        d.is_active = d.id === id;
      });
      Object.keys(MOCK_DATA.deckDetails).forEach((k) => {
        const numId = Number(k);
        MOCK_DATA.deckDetails[numId].is_active = numId === id;
      });
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
    console.info(
      '[jp-tcgbook] mockData 読込:',
      master.length,
      '枚（ブラウザモード）。ランク内訳:',
      RANK_ORDER.reduce((acc, r) => {
        acc[r] = (acc[r] || 0) + 1;
        return acc;
      }, {}),
    );
  }
})(window);

/**
 * サーバーAPI薄ラッパ（結果は NUI.on で受信）
 */
(function (global) {
  const N = global.NUI;

  global.api = {
    openBook() {
      N.send('openBook', {});
    },
    closeBook() {
      N.send('closeBook', {});
    },
    selectDeck(deckId) {
      N.send('selectDeck', { deck_id: deckId });
    },
    addCardToDeck(deckId, cardId) {
      N.send('addCardToDeck', { deck_id: deckId, card_id: cardId });
    },
    removeDeckCard(deckId, slot) {
      N.send('removeDeckCard', { deck_id: deckId, slot });
    },
    createDeck(name) {
      N.send('createDeck', { name });
    },
    duplicateDeck(deckId) {
      N.send('duplicateDeck', { deck_id: deckId });
    },
    deleteDeck(deckId) {
      N.send('deleteDeck', { deck_id: deckId });
    },
    renameDeck(deckId, newName) {
      N.send('renameDeck', { deck_id: deckId, new_name: newName });
    },
    setActiveDeck(deckId) {
      N.send('setActiveDeck', { deck_id: deckId });
    },
    battleSetWaiting(waiting) {
      N.send('battleSetWaiting', { waiting: !!waiting });
    },
    battleCallById(targetServerId) {
      N.send('battleCallById', { target_server_id: targetServerId });
    },
    battleVirtualLeave() {
      N.send('battleVirtualLeave', {});
    },
    battleSoloVirtualWireTest() {
      N.send('battleSoloVirtualWireTest', {});
    },
    battleDebugLookupId(targetServerId) {
      N.send('battleDebugLookupId', { target_server_id: targetServerId });
    },
    battleDebugStartCpu() {
      N.send('battleDebugStartCpu', {});
    },
    battleDebugPlace(cellIndex, handIndex) {
      N.send('battleDebugPlace', { cell_index: cellIndex, hand_index: handIndex });
    },
    battleDebugLeave() {
      N.send('battleDebugLeave', {});
    },
    battlePvpPlace(payload) {
      const p = payload && typeof payload === 'object' ? payload : {};
      N.send('battlePvpPlace', {
        session_id: p.session_id,
        turn_no: p.turn_no,
        cell_index: p.cell_index,
        hand_index: p.hand_index,
      });
    },
    battlePvpLeave() {
      N.send('battlePvpLeave', {});
    },
    battlePvpRequestState(payload) {
      const p = payload && typeof payload === 'object' ? payload : {};
      N.send('battlePvpRequestState', { session_id: p.session_id });
    },
  };
})(window);

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
  };
})(window);

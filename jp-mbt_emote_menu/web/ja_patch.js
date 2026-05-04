// web/ja_patch.js — NUI のハードコード英語ラベルを日本語に置換
// 注意: locales/ja.lua の翻訳キーで反映されない箇所のみ補完するための保険レイヤー
(function () {
  if (window.__mbtJaPatchLoaded) return;
  window.__mbtJaPatchLoaded = true;

  const dict = {
    // よく現れる UI 単語 (locale 経由でも反映されるはず。冗長保険)
    'Emote Menu': 'エモートメニュー',
    'Search emotes...': 'エモートを検索...',
    'Search': '検索',
    'All': 'すべて',
    'Favorites': 'お気に入り',
    'Recent': '最近使用',
    'Top': 'トップ',
    'Lists': 'リスト',
    'Custom Lists': 'カスタムリスト',
    'New List': '新規リスト',
    'Play': '再生',
    'Stop': '停止',
    'Cancel': 'キャンセル',
    'Random': 'ランダム',
    'Settings': '設定',
    'Close': '閉じる',
    'Accept': '承諾',
    'Decline': '拒否',
    'Sort A-Z': '昇順 (A→Z)',
    'Sort Z-A': '降順 (Z→A)',
    'Sort by Category': 'カテゴリ順',
    'With Props': '小道具あり',
    'Solo': 'ソロ',
    'Shared': '共有',
    'No emotes found': 'エモートが見つかりません',
    'Drag emote here': 'ここにエモートをドラッグ',
    'Quick Bind': 'クイックバインド',
    'Empty': '空',
    'Scroll to change · Release to play': 'スクロールで変更・離して再生',
    'X to remove': 'X で削除',
    'Removed': '削除しました',
    'Searching players...': 'プレイヤーを検索中...',
    'No players nearby': '近くにプレイヤーがいません',
    'Invite sent!': '招待を送信しました！',
    'Send to nearest': '最も近い人に送信',
    'Retry': '再試行',
    'Drag or use + to add': 'ドラッグまたは + で追加',
    'Clear playlist': 'プレイリストをクリア',
    'Loop enabled': 'ループ オン',
    'Loop disabled': 'ループ オフ',
    'Playlist': 'プレイリスト',
    'Preview': 'プレビュー',
    'Partner': 'パートナー',
    'Wheel': 'ホイール',
    'Emotes': 'エモート',
    'Props': '小道具',
    'Dances': 'ダンス',
    'Expressions': '表情',
    'Walk Styles': '歩き方',
    'Animals': '動物',
    'Emojis': '絵文字',
    'Add to Favorites': 'お気に入りに追加',
    'Remove from Favorites': 'お気に入りから削除',
    'Set Keybind': 'キー割り当て',
    'Playing': '再生中',
    'Idle': '待機中',
    'Walk Style': '歩き方',
    'Import': 'インポート',
    'Export': 'エクスポート',
    'Delete': '削除',
    'Rename': '名前変更',
    'Save': '保存',
    'wants to play': 'があなたと一緒にエモートをしたがっています',
  };

  const placeholderDict = {
    'Search emotes...': 'エモートを検索...',
    'Search...': '検索...',
    'List name': 'リスト名',
    'New list name': '新規リスト名',
  };

  function translateNode(node) {
    if (node.nodeType === 3) {
      const t = node.nodeValue;
      if (!t) return;
      const trimmed = t.trim();
      if (!trimmed) return;
      if (dict[trimmed]) {
        node.nodeValue = t.replace(trimmed, dict[trimmed]);
      }
    } else if (node.nodeType === 1) {
      // placeholder / aria-label / title 属性
      if (node.placeholder && placeholderDict[node.placeholder]) {
        node.placeholder = placeholderDict[node.placeholder];
      }
      const aria = node.getAttribute && node.getAttribute('aria-label');
      if (aria && dict[aria]) node.setAttribute('aria-label', dict[aria]);
      const title = node.getAttribute && node.getAttribute('title');
      if (title && dict[title]) node.setAttribute('title', dict[title]);

      for (let i = 0; i < node.childNodes.length; i++) {
        translateNode(node.childNodes[i]);
      }
    }
  }

  function run() {
    translateNode(document.body);
  }

  const obs = new MutationObserver(() => {
    // throttle
    if (run._t) return;
    run._t = setTimeout(() => { run._t = null; run(); }, 50);
  });

  document.addEventListener('DOMContentLoaded', () => {
    run();
    obs.observe(document.body, { childList: true, subtree: true, characterData: true });
  });

  // すでにロード済みの場合
  if (document.readyState !== 'loading') {
    run();
    obs.observe(document.body, { childList: true, subtree: true, characterData: true });
  }
})();

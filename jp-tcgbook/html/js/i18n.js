/**
 * BOOK UI 言語（クライアントのみ・localStorage）。ゲーム本体 locales とは別。
 */
(function (global) {
  const STORAGE_KEY = 'jp-tcgbook-ui-lang';
  const FALLBACK = 'ja';

  /** @type {Record<string, Record<string, string>>} */
  const STR = {
    ja: {
      lang_label: '言語',
      lang_select_aria: '表示言語',
      lang_option_ja: '日本語',
      lang_option_en: 'English',
      nav_book_menu: 'BOOK メニュー',
      tab_collection: '📖 コレクション',
      tab_deck: '🎴 デッキ編成',
      tab_battle: '⚔ 対戦',
      tab_history: '📜 対戦履歴',
      tab_ranking: '🏆 ランキング',
      help_title: 'ルールブック',
      help_aria: 'ヘルプ',
      footer_keyboard_hints_html:
        '<kbd>Tab</kbd> 切替 ・ <kbd>ESC</kbd> 閉じる（モーダル優先）',
      sort_group_aria: 'ソート',
      hist_table_aria: '対戦履歴',
      header_stats_empty: '所持: — ・ レート —',
      header_stats_fmt:
        '所持: {n} 枚 ・ Lv {lv}（EXP {xp}）・ 連勝 {st} ・ レート {r} ・ {wl}',
      header_record_wl: '{w}勝 {l}敗',
      header_player_fallback: 'プレイヤー',
      hist_lead: '直近 ',
      hist_trail: ' 件。',
      hist_empty: '対戦履歴はまだありません。',
      hist_th_time: '日時',
      hist_th_opponent: '相手',
      hist_th_result: '結果',
      hist_th_score: 'スコア',
      hist_th_rating: 'レート（変化）',
      hist_th_copy: '敗北コピー',
      ranking_placeholder_html:
        '🏆 ランキングタブは<strong>仕様検討中</strong>です（表示・並び・更新タイミングは後続 PHASE で決定）。',
      confirm_title: '確認',
      confirm_cancel: 'キャンセル',
      confirm_ok: 'OK',
      history_help_on:
        '開発構成（DebugCommands）: 疑似PvPソロの完走も本番 Finish 経路で履歴・レート・EXP・敗北コピーに反映されます（相手はDBの検証用ダミー）。',
      history_help_off:
        '開発コマンド無効時は疑似PvPソロは開始できません。この一覧には<strong>リアルPvPを盤面まで完走</strong>した試合が表示されます。',
      history_note_on:
        'ソロ完走も一覧に載ります。相手は「仮想対戦相手（検証）」表示・DB上はダミー citizenid です。',
      history_note_off:
        'この環境ではソロ経由の履歴はありません。仮想ロビーで二人がリアルPvPを完了すると表示されます。',
      hist_outcome_win: '勝ち',
      hist_outcome_lose: '負け',
      hist_outcome_draw: '引分',
      hist_copy_prefix: 'コピー: ',
      hist_copy_yes: 'コピーあり',
      error_generic: 'エラーが発生しました',
      col_search_placeholder: 'カード名・IDで検索',
      col_sidebar_aria: '検索・フィルタ',
      col_type_heading: 'タイプ',
      col_rank_heading: 'ランク',
      filter_all: 'すべて',
      filter_free: 'フリー',
      filter_designated: '指定',
      completion_label: '完成度',
      sort_label: '並び替え',
      sort_rank: 'ランク',
      sort_date: '入手',
      sort_name: '名前',
      col_detail_aria: 'カード詳細',
    },
    en: {
      lang_label: 'Language',
      lang_select_aria: 'Display language',
      lang_option_ja: 'Japanese',
      lang_option_en: 'English',
      nav_book_menu: 'BOOK menu',
      tab_collection: '📖 Collection',
      tab_deck: '🎴 Decks',
      tab_battle: '⚔ Battle',
      tab_history: '📜 Match history',
      tab_ranking: '🏆 Ranking',
      help_title: 'Rulebook',
      help_aria: 'Help',
      footer_keyboard_hints_html:
        '<kbd>Tab</kbd>: switch tabs · <kbd>ESC</kbd>: close (modal first)',
      sort_group_aria: 'Sort',
      hist_table_aria: 'Match history',
      header_stats_empty: 'Owned: — · Rating —',
      header_stats_fmt: 'Owned: {n} cards · Lv {lv} (EXP {xp}) · Streak {st} · Rating {r} · {wl}',
      header_record_wl: '{w}W–{l}L',
      header_player_fallback: 'Player',
      hist_lead: 'Recent ',
      hist_trail: ' matches.',
      hist_empty: 'No match history yet.',
      hist_th_time: 'Time',
      hist_th_opponent: 'Opponent',
      hist_th_result: 'Result',
      hist_th_score: 'Score',
      hist_th_rating: 'Rating (Δ)',
      hist_th_copy: 'Defeat copy',
      ranking_placeholder_html:
        '🏆 Ranking tab is <strong>under design</strong> (layout, sort order, and refresh timing will follow in a later phase).',
      confirm_title: 'Confirm',
      confirm_cancel: 'Cancel',
      confirm_ok: 'OK',
      history_help_on:
        'Dev (DebugCommands): Solo pseudo-PvP completes use the same Finish pipeline as live PvP (history, rating, EXP, defeat copy). Opponent is the verification dummy in DB.',
      history_help_off:
        'When debug commands are off, solo pseudo-PvP cannot start. This list shows <strong>real PvP matches played to completion</strong>.',
      history_note_on:
        'Solo completes appear here too. Opponent shows as “Virtual opponent (verification)” with dummy citizenid in DB.',
      history_note_off:
        'No solo-derived history in this setup. Complete a real PvP match via the lobby to see rows.',
      hist_outcome_win: 'Win',
      hist_outcome_lose: 'Loss',
      hist_outcome_draw: 'Draw',
      hist_copy_prefix: 'Copy: ',
      hist_copy_yes: 'Copy granted',
      error_generic: 'Something went wrong.',
      col_search_placeholder: 'Search name or ID',
      col_sidebar_aria: 'Search & filters',
      col_type_heading: 'Type',
      col_rank_heading: 'Rank',
      filter_all: 'All',
      filter_free: 'Free',
      filter_designated: 'Designated',
      completion_label: 'Completion',
      sort_label: 'Sort',
      sort_rank: 'Rank',
      sort_date: 'Acquired',
      sort_name: 'Name',
      col_detail_aria: 'Card details',
    },
  };

  /** @type {string} */
  let currentLang = FALLBACK;
  const listeners = [];

  function normalize(lang) {
    return lang === 'en' ? 'en' : 'ja';
  }

  function readStoredLang() {
    try {
      const s = global.localStorage.getItem(STORAGE_KEY);
      if (s) return normalize(s);
    } catch (_) {}
    return FALLBACK;
  }

  /** @param {string} key */
  function t(key) {
    const pack = STR[currentLang] || STR[FALLBACK];
    const fb = STR[FALLBACK];
    if (pack && Object.prototype.hasOwnProperty.call(pack, key)) return pack[key];
    if (fb && Object.prototype.hasOwnProperty.call(fb, key)) return fb[key];
    return key;
  }

  function getLang() {
    return currentLang;
  }

  function applyChrome() {
    document.documentElement.lang = currentLang === 'en' ? 'en' : 'ja';

    document.querySelectorAll('[data-i18n]').forEach((el) => {
      const key = el.getAttribute('data-i18n');
      if (!key) return;
      el.textContent = t(key);
    });

    document.querySelectorAll('[data-i18n-html]').forEach((el) => {
      const key = el.getAttribute('data-i18n-html');
      if (!key) return;
      el.innerHTML = t(key);
    });

    document.querySelectorAll('[data-i18n-placeholder]').forEach((el) => {
      const key = el.getAttribute('data-i18n-placeholder');
      if (!key || !('placeholder' in el)) return;
      el.placeholder = t(key);
    });

    document.querySelectorAll('[data-i18n-title]').forEach((el) => {
      const key = el.getAttribute('data-i18n-title');
      if (!key) return;
      el.title = t(key);
    });

    document.querySelectorAll('[data-i18n-aria]').forEach((el) => {
      const key = el.getAttribute('data-i18n-aria');
      if (!key) return;
      el.setAttribute('aria-label', t(key));
    });

    const sel = document.getElementById('bookLangSelect');
    if (sel && 'value' in sel) {
      sel.value = currentLang;
    }

    const loJa = document.querySelector('#bookLangSelect option[value="ja"]');
    const loEn = document.querySelector('#bookLangSelect option[value="en"]');
    if (loJa) loJa.textContent = t('lang_option_ja');
    if (loEn) loEn.textContent = t('lang_option_en');
  }

  /** @param {string} lang */
  function setLang(lang) {
    currentLang = normalize(lang);
    try {
      global.localStorage.setItem(STORAGE_KEY, currentLang);
    } catch (_) {}
    applyChrome();
    listeners.forEach((fn) => {
      try {
        fn(currentLang);
      } catch (_) {}
    });
  }

  function init() {
    currentLang = readStoredLang();
    applyChrome();
  }

  /** @param {(lang: string) => void} fn */
  function onLocaleChange(fn) {
    listeners.push(fn);
  }

  global.I18n = {
    init,
    t,
    getLang,
    setLang,
    applyChrome,
    onLocaleChange,
  };
})(window);

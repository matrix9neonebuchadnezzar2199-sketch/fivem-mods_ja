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
      'player.unknown': '不明なプレイヤー',
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
      rank_season_evergreen: 'シーズン：通年開催',
      rank_table_aria: 'ランキング一覧',
      rank_th_rank: '順位',
      rank_th_tier: '段位',
      rank_th_name: '名前',
      rank_th_rating: 'レート',
      rank_th_lv: 'Lv',
      rank_th_exp: 'EXP',
      rank_th_streak: '連勝',
      rank_loading: '読み込み中…',
      rank_empty: 'データがありません',
      rank_sep: '⋯ ⋯ ⋯',
      rank_tier_placeholder: '—',
      rank_my_rank: 'あなたの順位: {rank} / {total}',
      rank_my_tier_label: '段位:',
      rank_my_detail: 'レート {rating} ・ Lv {lv} ・ EXP {exp} ・ 連勝 {streak}',
      'rank.ss': '神話',
      'rank.s': '竜',
      'rank.a': '星霊',
      'rank.b': '白金',
      'rank.c': '金',
      'rank.d': '銀',
      'rank.e': '鉄',
      'rank.f': '青銅',
      'rank.g': '木',
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
      doc_title: 'BOOK',
      modal_close_aria: '閉じる',
      deck_sidebar_aria: 'デッキ一覧',
      deck_pane_title_decks: 'DECKS',
      deck_new_btn_title: '新規デッキ',
      deck_help_btn_title: 'デッキ編成ヘルプ',
      deck_help_btn_aria: 'デッキ編成ヘルプ',
      deck_save_saved: '保存済み',
      deck_save_saving: '保存中…',
      deck_save_error: 'エラー',
      deck_save_retry: '再同期',
      deck_counter_cards_suffix: '枚',
      deck_shitei_label: '指定',
      btn_set_active_deck: '★ 使用デッキに設定',
      btn_copy_deck: '📋 コピーして新規追加',
      btn_shuffle_test: '🔀 シャッフルテスト',
      btn_delete_deck: '🗑 削除',
      deck_tooltip_copy: '現在のデッキをコピーして新しく追加',
      deck_tooltip_shuffle: 'ローカル試算のみ。本番対戦時はサーバー側でシャッフルされます',
      deck_coll_aria: '所持カードから追加',
      deck_coll_title: '所持カード',
      deck_coll_search_ph: '検索…',
      deck_chip_type_aria: 'タイプ',
      deck_chip_rank_aria: 'ランク',
      deck_rank_all: '全ランク',
      help_modal_title: 'ルールブック',
      help_sec_intro_title: 'はじめに（初回配布）',
      help_sec_intro_p:
        '初回に <code>/book</code> を開くと、フリーカードが10枚配布され、「マイデッキ」が自動作成されます。',
      help_sec_rank_title: 'カードのランク',
      help_sec_rank_table_head: '<tr><th>区分</th><th>ランク</th><th>同名上限/デッキ</th><th>編成枠</th></tr>',
      help_sec_rank_row1: '<tr><td>指定</td><td>UR / SS</td><td>各1枚</td><td>指定枠 合計2枚まで</td></tr>',
      help_sec_rank_row2: '<tr><td>フリー</td><td>S〜C</td><td>各2枚</td><td>残り8枚</td></tr>',
      help_sec_rank_rows_html:
        '<tr><td>指定</td><td>UR / SS</td><td>各1枚</td><td>指定枠 合計2枚まで</td></tr><tr><td>フリー</td><td>S〜C</td><td>各2枚</td><td>残り8枚</td></tr>',
      help_sec_deck_rules_title: 'デッキ編成ルール',
      help_sec_deck_rules_li1: '1デッキ10枚。指定カードは合計2枚まで。',
      help_sec_deck_rules_li2: '使用デッキに設定できるのは <strong>10枚完成</strong> のデッキのみ。',
      help_sec_deck_rules_li3: 'デッキは最大10個まで。最後の1個は削除できません。',
      help_sec_controls_title: '操作方法',
      help_sec_controls_p:
        '📖 でこのヘルプを開閉。ヘルプ表示中は <kbd>ESC</kbd> でヘルプのみ閉じます。',
      help_sec_acquire_title: 'カードの入手（方針）',
      help_sec_acquire_p:
        '<strong>トレードはありません。</strong>入手は <strong>対戦</strong> と <strong>パック購入（10枚）</strong> を想定しています。対戦では <strong>敗北した側のデッキから 1 枚がランダムに選ばれ、勝者に「コピー」として渡る</strong>予定です（あなたのデッキ枚数は減りません）。パックの排出レンジ・購入 UI は<strong>仕様確定まで保留</strong>です。',
      help_sec_battle_deck_title: 'バトルでのデッキ運用',
      help_sec_battle_deck_p:
        '対戦タブでは <strong>使用デッキ（★）</strong> の準備状況を確認できます。マッチングや盤面は今後のフェーズで追加します。使用デッキは <strong>10枚完成</strong> のデッキのみ設定できます。',
      deck_help_modal_title: 'デッキ編成ヘルプ',
      deck_help_sec_tier_title: 'ランク階層',
      deck_help_sec_tier_p: '強さの目安は <strong>UR ＞ SS ＞ S ＞ A ＞ B ＞ C</strong> です。',
      deck_help_sec_rules_title: '編成ルール',
      deck_help_sec_rules_li1: '1デッキ <strong>10枚</strong>。指定カードは <strong>合計2枚まで</strong>（残り8枠はフリー）。',
      deck_help_sec_rules_li2: '指定（UR/SS）は同名 <strong>1枚まで</strong>。フリーは同名 <strong>2枚まで</strong>。',
      deck_help_sec_rules_li3: '<strong>使用デッキ</strong>に設定できるのは <strong>10枚完成</strong> のデッキのみです。',
      deck_help_sec_autosave_title: '自動保存・デッキ切替',
      deck_help_sec_autosave_p:
        'カードの<strong>＋追加</strong>やスロットの<strong>×解除</strong>は、設定された間隔でまとめてサーバーへ順に送信されます（ヘッダーのインジケータが保存状態を示します）。失敗時は<strong>再同期</strong>で一覧を取り直せます。左リストでデッキを選ぶとエディタが切り替わります。',
      deck_shuffle_modal_title: 'シャッフルテスト（先頭5枚）',
      deck_shuffle_modal_p:
        'ブラウザ内で現在の10枚をシャッフルした結果の<strong>先頭5枚</strong>です。対戦開始時の実際の順序はサーバー側のシャッフルになります。',
      deck_shuffle_again: 'もう一度シャッフル',
      deck_delete_modal_title: 'デッキ削除の確認',
      deck_delete_modal_p:
        'このデッキを削除しますか？この操作は取り消せません（最後の1デッキは削除できません）。',
      deck_delete_cancel: 'キャンセル',
      deck_delete_confirm: '削除する',
      app_battle_tab_blocked: '対戦中は他のタブに切り替えられません。全画面の「対戦終了」で抜けてください。',
      app_book_close_solo:
        'BOOK を閉じますか？\n\nソロ検証の仮想接続を終了します。',
      app_book_close_virtual:
        'BOOK を閉じますか？\n\n仮想対戦の接続中、または対戦アリーナ進行中です。続行すると終了し、接続中なら相手側も切断されます。',
      app_match_prep: '対戦準備中…',
      app_err_book_data: 'データ取得に失敗しました',
      app_err_ranking: 'ランキングを取得できませんでした',
      app_err_deck_load: 'デッキ取得に失敗しました',
      app_err_deck_save: 'デッキ更新に失敗しました',
      app_err_list: '一覧の更新に失敗しました',
      app_err_short: 'エラー',
      app_dbg_lookup_fail: '検索に失敗しました',
      app_pvp_err_wrap: '対戦エラー（{reason}）',
      pvp_err_session_not_found: '対戦セッションが見つかりません',
      pvp_err_not_in_session: 'この対戦の参加者ではありません',
      pvp_err_not_your_turn: '自分のターンではありません',
      pvp_err_turn_no_mismatch: '手番情報が古いです（画面を更新してください）',
      pvp_err_invalid_cell: 'マス指定が不正です',
      pvp_err_cell_occupied: 'そのマスは既に埋まっています',
      pvp_err_invalid_hand_index: '手札の指定が不正です',
      pvp_err_hand_card_missing: 'その手札はありません',
      col_type_shitei: '指定',
      col_type_free: 'フリー',
      col_detail_not_owned: '未所持のカードです',
      col_detail_pick_hint: 'カードを選択すると詳細が表示されます',
      col_detail_owned_fmt: '{id} ・ 所持 {count} 枚',
      col_btn_goto_deck: 'デッキ編成へ',
      col_acquire_hint:
        '入手: 対戦で敗北時、相手に自分のデッキから1枚をランダムコピー（実装は後続）／パック購入（仕様は別途・保留）',
      deck_select_prompt: 'デッキを選択してください',
      deck_slot_empty: '空き',
      deck_slot_remove_title: 'スロットから外す',
      deck_new_base_name: '新規デッキ',
      deck_builtin_my_deck: 'マイデッキ',
      deck_stat_total_pwr: '総合PWR',
      deck_stat_avg_pwr: '平均PWR',
      deck_stat_max_stat: '最大ステ',
      deck_stat_shitei_free: '指定/フリー',
      deck_stat_rank_breakdown: 'ランク内訳',
      deck_owned_suffix: '枚',
      deck_owned_count_fmt: '{n}枚',
      deck_inv_badge_0: '残0',
      deck_inv_badge_remain: '残{n}',
      deck_name_input_aria: 'デッキ名',
      deck_rename_btn_title: '名前を編集',
      deck_rename_btn_aria: '名前を編集',
      battle_no_deck_lead: '使用デッキ（★）が設定されていません。',
      battle_no_deck_hint: 'デッキ編成で 10 枚揃ったデッキを「使用デッキに設定」してください。',
      battle_goto_deck: 'デッキ編成へ',
      battle_loading_hint: 'アクティブデッキを読み込み中です。',
      battle_refresh_deck: '再読込',
      battle_ready_ok: '対戦準備OK（10枚）',
      battle_ready_short: '枚数不足（{filled} / {size}）',
      battle_row_state: '状態',
      battle_row_rating: 'レート',
      battle_row_pwr: '総合PWR',
      battle_readiness_title: '使用デッキ',
      battle_review_deck: 'デッキを確認・編集',
      battle_section_practice: 'フリーバトル（練習）',
      battle_practice_hint:
        'CPU相手です。ランキング・対戦履歴・報酬の対象外です（PHASE A ルール）。',
      battle_practice_start: 'CPU と対戦する',
      battle_practice_need_active_deck: 'アクティブデッキが無いときは開始できません（デッキ編成で選択してください）。',
      battle_practice_need_full_deck: 'デッキが10枚そろうと開始できます（現在 {filled} / {size}）。',
      battle_practice_blocked_virtual:
        '仮想対戦に接続中は開始できません（先に「切断する」でロビーを抜けてください）。',
      battle_peer_solo_label: 'ソロ検証（2人目なし）',
      battle_mode_solo_verify: 'ソロ検証',
      battle_role_caller: '呼び出し側',
      battle_role_callee: '待受側',
      battle_connected: '接続済み',
      battle_peer_html: '相手のサーバーID <strong>{id}</strong>',
      battle_virtual_no_player_note:
        '実プレイヤーはいません。通信経路と UI のみの確認です。盤面・報酬は未実装です。',
      battle_virtual_after_match_note:
        'マッチ成立後は全画面アリーナで対戦します（サーバー権威・PHASE A）。敗北時のカードコピー付与は別 PHASE。',
      battle_section_virtual: '仮想対戦',
      battle_disconnect: '切断する',
      battle_section_debug_virtual: '仮想対戦（デバッグ／検証）',
      battle_debug_virtual_hint:
        '近距離招待は使わず、<strong>相手プレイヤーのサーバーID（番号）</strong>で呼び出します。待ち受ける側は「招待待機」を ON にして番号を伝え、呼ぶ側がその番号を入力します。',
      battle_label_your_server_id: 'あなたの番号（サーバーID）',
      battle_wait_stop: '招待待機をやめる',
      battle_wait_start: '招待待機を開始',
      battle_label_peer_number: '相手の番号',
      battle_call_placeholder: '例: 12',
      battle_call_btn: '呼び出す',
      battle_solo_wire_btn: '1人で仮想接続の往復を試す',
      battle_solo_wire_hint:
        '友達のクライアントは不要です（<code>Config.DebugCommands</code> 有効時のみサーバが応答）。F8 や <code>[jp-tcgbook][wire]</code> ログで NUI→client→server→client→NUI を追えます。',
      battle_battleid_note:
        'コマンド <code>/tcg_battleid</code>（デバッグ権限）でも自分の番号を確認できます。',
      battle_debug_lobby_section: 'デバッグ用ロビー',
      battle_debug_lobby_hint:
        '検索はオンライン確認をしません（応答のみの検証用）。「疑似 PvP 対戦を開始」は <code>battle_pvp.lua</code> 本番経路（仮想相手・サーバー AI）。CPU練習は対戦タブ上部の「フリーバトル」から。',
      battle_debug_lookup_label: '検索するサーバーID',
      battle_dbg_lookup_ph: '例: 99',
      battle_dbg_lookup_btn: '検索',
      battle_dbg_lookup_result: '検索結果:',
      battle_dbg_lookup_ok: '応答OK',
      battle_dbg_start_cpu: 'CPU対戦を開始',
      battle_dbg_start_pvp_solo: '疑似 PvP 対戦を開始',
      battle_debug_panel_title: 'デバッグ用ロビー',
      battle_debug_panel_note:
        '<code>Config.DebugCommands</code> が有効なときのみ表示されます。本番 PvP とは別経路です。',
      battle_debug_toggle_label: 'デバッグ用ロビーを表示する',
      battle_you: 'あなた',
      battle_opp_pvp: '相手',
      battle_opp_cpu: 'CPU',
      battle_line_first_turn:
        '先攻: {fp} ・ いまのターン: <strong>{turn}</strong> ・ {opp}手札残: {n}',
      battle_pvp_status_end: '終了: あなた {my} vs 相手 {op}',
      battle_pvp_status_playing: 'いまのターン: {who} ・ 相手手札残: {n}',
      battle_result_win: 'あなたの勝ち',
      battle_result_lose: '{opp} の勝ち',
      battle_result_draw: '引き分け',
      battle_score_line: 'スコア（盤の色＋手札）: あなた {h} vs {opp} {c}',
      battle_hint_pseudo_off: '疑似PvP（本番経路オフ）ではカードの付与・敗北コピーはありません。',
      battle_hint_win_no_card: '勝利時のカード入手はありません（敗北時コピーのみ）。',
      battle_defeat_copy: '敗北コピー入手:',
      battle_foot_back_tab: '「対戦タブに戻る」でロビーへ戻ります',
      battle_btn_back_tab: '対戦タブに戻る',
      battle_foot_cpu_end: '上部の「対戦終了」でロビーに戻れます',
      battle_sub_pvp: 'vs 相手 · PHASE A',
      battle_sub_cpu: 'vs CPU · PHASE A',
      battle_resign: '投了',
      battle_end: '終了',
      battle_quit_cpu: '対戦終了',
      battle_invalid_batch_title:
        'サーバーで不正着手5ケース連続検証（ログ）。盤に1枚あると cell_occ も実行されます',
      battle_invalid_batch_btn: 'PvP不正5',
      battle_grid_aria: '3x3盤面',
      battle_cell_aria: 'マス {i}',
      battle_log_head: 'ログ',
      battle_footnote: '隣接比較・配置直後のみ奪取・連鎖なし',
      battle_hand_head: '手札',
      battle_hand_hint: 'カードを選び、空マスをタップ（最大5枚・縦並び）',
      battle_err_pick_hand: '先に手札のカードを選んでください',
      battle_err_bad_pvp_state: '対戦状態が不正です（再読込してください）',
      battle_confirm_resign_pvp:
        '投了するとこの対局を負けとして終了し、相手のセッションも終了します。よろしいですか？',
      battle_confirm_quit_cpu: 'CPU対戦（練習）を終了しますか？',
      battle_err_peer_id: '相手の番号を入力してください',
      battle_leave_solo_confirm: 'ソロ検証の仮想接続を終了しますか？',
      battle_leave_virtual_confirm:
        '仮想対戦を終了しますか？\n\n相手側のセッションも終了します。誤操作防止のため確認しています。',
      battle_err_lookup_id: '検索するサーバーID を入力してください',
      battle_fullscreen_hint:
        '対戦は全画面で表示されています。終了は対戦画面上部の「対戦終了」から行ってください。',
      battle_footer_long:
        'フリーバトル（練習）はCPU相手でいつでも開始できます（経済対象外）。仮想ロビーでマッチしたプレイヤー同士も同一ルール（PHASE A）です。自動マッチングは別フェーズです。',
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
      'player.unknown': 'Unknown player',
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
      rank_season_evergreen: 'Season: evergreen',
      rank_table_aria: 'Ranking leaderboard',
      rank_th_rank: 'Rank',
      rank_th_tier: 'Tier',
      rank_th_name: 'Name',
      rank_th_rating: 'Rating',
      rank_th_lv: 'Lv',
      rank_th_exp: 'EXP',
      rank_th_streak: 'Streak',
      rank_loading: 'Loading…',
      rank_empty: 'No data',
      rank_sep: '⋯ ⋯ ⋯',
      rank_tier_placeholder: '—',
      rank_my_rank: 'Your rank: {rank} / {total}',
      rank_my_tier_label: 'Tier:',
      rank_my_detail: 'Rating {rating} · Lv {lv} · EXP {exp} · Streak {streak}',
      'rank.ss': 'Mythology',
      'rank.s': 'Dragon',
      'rank.a': 'Astral',
      'rank.b': 'Platinum',
      'rank.c': 'Gold',
      'rank.d': 'Silver',
      'rank.e': 'Iron',
      'rank.f': 'Bronze',
      'rank.g': 'Wood',
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
      doc_title: 'BOOK',
      modal_close_aria: 'Close',
      deck_sidebar_aria: 'Deck list',
      deck_pane_title_decks: 'DECKS',
      deck_new_btn_title: 'New deck',
      deck_help_btn_title: 'Deck builder help',
      deck_help_btn_aria: 'Deck builder help',
      deck_save_saved: 'Saved',
      deck_save_saving: 'Saving…',
      deck_save_error: 'Error',
      deck_save_retry: 'Resync',
      deck_counter_cards_suffix: 'cards',
      deck_shitei_label: 'Designated',
      btn_set_active_deck: '★ Set as active deck',
      btn_copy_deck: '📋 Copy as new deck',
      btn_shuffle_test: '🔀 Shuffle test',
      btn_delete_deck: '🗑 Delete',
      deck_tooltip_copy: 'Copy the current deck as a new deck',
      deck_tooltip_shuffle:
        'Local simulation only. Live battles shuffle on the server.',
      deck_coll_aria: 'Add from owned cards',
      deck_coll_title: 'Owned cards',
      deck_coll_search_ph: 'Search…',
      deck_chip_type_aria: 'Type',
      deck_chip_rank_aria: 'Rank',
      deck_rank_all: 'All ranks',
      help_modal_title: 'Rulebook',
      help_sec_intro_title: 'Getting started (first launch)',
      help_sec_intro_p:
        'The first time you open <code>/book</code>, you receive 10 free cards and a “My Deck” is created automatically.',
      help_sec_rank_title: 'Card ranks',
      help_sec_rank_table_head:
        '<tr><th>Group</th><th>Ranks</th><th>Same-name limit/deck</th><th>Slots</th></tr>',
      help_sec_rank_row1:
        '<tr><td>Designated</td><td>UR / SS</td><td>1 each</td><td>Up to 2 designated slots total</td></tr>',
      help_sec_rank_row2:
        '<tr><td>Free</td><td>S–C</td><td>2 each</td><td>Remaining 8 slots</td></tr>',
      help_sec_rank_rows_html:
        '<tr><td>Designated</td><td>UR / SS</td><td>1 each</td><td>Up to 2 designated slots total</td></tr><tr><td>Free</td><td>S–C</td><td>2 each</td><td>Remaining 8 slots</td></tr>',
      help_sec_deck_rules_title: 'Deck rules',
      help_sec_deck_rules_li1: '10 cards per deck. Up to 2 designated cards total.',
      help_sec_deck_rules_li2:
        'Only <strong>complete 10-card</strong> decks can be set as the active deck.',
      help_sec_deck_rules_li3: 'Up to 10 decks. You cannot delete your last deck.',
      help_sec_controls_title: 'Controls',
      help_sec_controls_p:
        '📖 toggles this help. While help is open, <kbd>ESC</kbd> closes help only.',
      help_sec_acquire_title: 'Acquiring cards (policy)',
      help_sec_acquire_p:
        '<strong>No trading.</strong> Acquisition is planned via <strong>battles</strong> and <strong>pack purchases (10 cards)</strong>. In battles, <strong>one random card from the loser’s deck will be copied to the winner</strong> (your deck count does not decrease). Pack odds and purchase UI are <strong>pending final design</strong>.',
      help_sec_battle_deck_title: 'Decks in battle',
      help_sec_battle_deck_p:
        'The Battle tab shows readiness for your <strong>active deck (★)</strong>. Matchmaking and the board come in later phases. Only <strong>complete 10-card</strong> decks can be active.',
      deck_help_modal_title: 'Deck builder help',
      deck_help_sec_tier_title: 'Rank tiers',
      deck_help_sec_tier_p: 'Rough strength: <strong>UR &gt; SS &gt; S &gt; A &gt; B &gt; C</strong>.',
      deck_help_sec_rules_title: 'Rules',
      deck_help_sec_rules_li1:
        '<strong>10 cards</strong> per deck. Up to <strong>2 designated</strong> cards total (8 free slots remain).',
      deck_help_sec_rules_li2:
        'Designated (UR/SS): <strong>1 copy</strong> per name. Free: <strong>2 copies</strong> per name.',
      deck_help_sec_rules_li3:
        'Only <strong>complete 10-card</strong> decks can be set as the <strong>active deck</strong>.',
      deck_help_sec_autosave_title: 'Autosave & switching',
      deck_help_sec_autosave_p:
        '<strong>+ Add</strong> and slot <strong>× remove</strong> are batched to the server on an interval (header indicator shows status). On failure, use <strong>Resync</strong> to reload. Pick a deck in the left list to switch editors.',
      deck_shuffle_modal_title: 'Shuffle test (first 5)',
      deck_shuffle_modal_p:
        'The <strong>first five</strong> after shuffling your current 10 cards in the browser. Live battle order is shuffled on the server.',
      deck_shuffle_again: 'Shuffle again',
      deck_delete_modal_title: 'Delete deck?',
      deck_delete_modal_p:
        'Delete this deck? This cannot be undone (you cannot delete your last deck).',
      deck_delete_cancel: 'Cancel',
      deck_delete_confirm: 'Delete',
      app_battle_tab_blocked:
        'You cannot switch tabs during battle. Use “End battle” on fullscreen view to exit.',
      app_book_close_solo:
        'Close BOOK?\n\nThis ends the solo verification virtual connection.',
      app_book_close_virtual:
        'Close BOOK?\n\nVirtual battle is connected or the arena is active. Continuing ends the session and disconnects the peer if connected.',
      app_match_prep: 'Preparing for battle…',
      app_err_book_data: 'Failed to load data',
      app_err_ranking: 'Could not load ranking',
      app_err_deck_load: 'Failed to load decks',
      app_err_deck_save: 'Failed to save deck',
      app_err_list: 'Failed to refresh list',
      app_err_short: 'Error',
      app_dbg_lookup_fail: 'Lookup failed',
      app_pvp_err_wrap: 'Battle error ({reason})',
      pvp_err_session_not_found: 'Battle session not found',
      pvp_err_not_in_session: 'You are not in this battle',
      pvp_err_not_your_turn: 'Not your turn',
      pvp_err_turn_no_mismatch: 'Stale turn info (refresh the screen)',
      pvp_err_invalid_cell: 'Invalid cell',
      pvp_err_cell_occupied: 'That cell is already occupied',
      pvp_err_invalid_hand_index: 'Invalid hand selection',
      pvp_err_hand_card_missing: 'That card is not in hand',
      col_type_shitei: 'Designated',
      col_type_free: 'Free',
      col_detail_not_owned: 'You do not own this card',
      col_detail_pick_hint: 'Select a card to see details',
      col_detail_owned_fmt: '{id} · Owned {count}',
      col_btn_goto_deck: 'Go to deck builder',
      col_acquire_hint:
        'Acquire: on defeat, opponent copies 1 random card from your deck (later) / packs (TBD).',
      deck_select_prompt: 'Select a deck',
      deck_slot_empty: 'Empty',
      deck_slot_remove_title: 'Remove from slot',
      deck_new_base_name: 'New deck',
      deck_builtin_my_deck: 'My Deck',
      deck_stat_total_pwr: 'Total PWR',
      deck_stat_avg_pwr: 'Avg PWR',
      deck_stat_max_stat: 'Max stat',
      deck_stat_shitei_free: 'Desig./Free',
      deck_stat_rank_breakdown: 'Rank breakdown',
      deck_owned_suffix: '',
      deck_owned_count_fmt: '{n} cards',
      deck_inv_badge_0: '0 left',
      deck_inv_badge_remain: '{n} left',
      deck_name_input_aria: 'Deck name',
      deck_rename_btn_title: 'Edit name',
      deck_rename_btn_aria: 'Edit name',
      battle_no_deck_lead: 'No active deck (★) is set.',
      battle_no_deck_hint:
        'In deck builder, complete 10 cards and “Set as active deck”.',
      battle_goto_deck: 'Deck builder',
      battle_loading_hint: 'Loading active deck…',
      battle_refresh_deck: 'Reload',
      battle_ready_ok: 'Ready (10 cards)',
      battle_ready_short: 'Incomplete ({filled} / {size})',
      battle_row_state: 'State',
      battle_row_rating: 'Rating',
      battle_row_pwr: 'Total PWR',
      battle_readiness_title: 'Active deck',
      battle_review_deck: 'Review / edit deck',
      battle_section_practice: 'Free battle (practice)',
      battle_practice_hint:
        'Vs CPU. Not ranked—no match history rewards or economy hooks (PHASE A rules).',
      battle_practice_start: 'Battle CPU',
      battle_practice_need_active_deck: 'Set an active deck in the deck builder first.',
      battle_practice_need_full_deck: 'Need 10 cards to start ({filled} / {size}).',
      battle_practice_blocked_virtual:
        'Disconnect from virtual battle first (“Disconnect”), then you can start practice.',
      battle_peer_solo_label: 'Solo verify (no second player)',
      battle_mode_solo_verify: 'Solo verify',
      battle_role_caller: 'Caller',
      battle_role_callee: 'Callee',
      battle_connected: 'Connected',
      battle_peer_html: 'Peer server ID <strong>{id}</strong>',
      battle_virtual_no_player_note:
        'No real opponent—wire/UI check only. Board and rewards not implemented.',
      battle_virtual_after_match_note:
        'After match, fullscreen arena (server authority · PHASE A). Defeat copy rewards are a separate phase.',
      battle_section_virtual: 'Virtual battle',
      battle_disconnect: 'Disconnect',
      battle_section_debug_virtual: 'Virtual battle (debug)',
      battle_debug_virtual_hint:
        'No proximity invites—call by <strong>peer server ID</strong>. Callee enables “Wait for invite” and shares ID; caller enters it.',
      battle_label_your_server_id: 'Your server ID',
      battle_wait_stop: 'Stop waiting',
      battle_wait_start: 'Wait for invite',
      battle_label_peer_number: 'Peer ID',
      battle_call_placeholder: 'e.g. 12',
      battle_call_btn: 'Call',
      battle_solo_wire_btn: 'Solo virtual wire round-trip',
      battle_solo_wire_hint:
        'No friend client needed (<code>Config.DebugCommands</code> allows server reply). Check F8 / <code>[jp-tcgbook][wire]</code> logs.',
      battle_battleid_note:
        'Command <code>/tcg_battleid</code> (debug) also shows your ID.',
      battle_debug_lobby_section: 'Debug lobby',
      battle_debug_lobby_hint:
        'Lookup skips online checks (response-only). “Start pseudo PvP” uses production <code>battle_pvp.lua</code> (virtual opponent / server AI). CPU practice is under Free battle above.',
      battle_debug_lookup_label: 'Lookup server ID',
      battle_dbg_lookup_ph: 'e.g. 99',
      battle_dbg_lookup_btn: 'Lookup',
      battle_dbg_lookup_result: 'Result:',
      battle_dbg_lookup_ok: 'OK',
      battle_dbg_start_cpu: 'Start CPU battle',
      battle_dbg_start_pvp_solo: 'Start pseudo PvP',
      battle_debug_panel_title: 'Debug lobby',
      battle_debug_panel_note:
        'Shown only when <code>Config.DebugCommands</code> is on. Separate from production PvP.',
      battle_debug_toggle_label: 'Show debug lobby',
      battle_you: 'You',
      battle_opp_pvp: 'Opponent',
      battle_opp_cpu: 'CPU',
      battle_line_first_turn:
        'First: {fp} · Turn: <strong>{turn}</strong> · {opp} hand: {n}',
      battle_pvp_status_end: 'End: you {my} vs opp {op}',
      battle_pvp_status_playing: 'Turn: {who} · Opp hand: {n}',
      battle_result_win: 'You win',
      battle_result_lose: '{opp} wins',
      battle_result_draw: 'Draw',
      battle_score_line: 'Score (board + hand): you {h} vs {opp} {c}',
      battle_hint_pseudo_off:
        'Pseudo PvP (prod path off): no card grants or defeat copies.',
      battle_hint_win_no_card: 'No card on win (defeat copy only).',
      battle_defeat_copy: 'Defeat copy:',
      battle_foot_back_tab: 'Use “Back to battle tab” to return to lobby',
      battle_btn_back_tab: 'Back to battle tab',
      battle_foot_cpu_end: 'Use “End battle” at the top to return',
      battle_sub_pvp: 'vs opponent · PHASE A',
      battle_sub_cpu: 'vs CPU · PHASE A',
      battle_resign: 'Resign',
      battle_end: 'End',
      battle_quit_cpu: 'End battle',
      battle_invalid_batch_title:
        'Server: five invalid-move cases (log). With one piece on board, cell_occ runs too.',
      battle_invalid_batch_btn: 'PvP invalid×5',
      battle_grid_aria: '3×3 board',
      battle_cell_aria: 'Cell {i}',
      battle_log_head: 'Log',
      battle_footnote: 'Adjacency compare · capture only on place · no chains',
      battle_hand_head: 'Hand',
      battle_hand_hint: 'Pick a card, tap empty cell (max 5, vertical)',
      battle_err_pick_hand: 'Select a hand card first',
      battle_err_bad_pvp_state: 'Invalid battle state (reload)',
      battle_confirm_resign_pvp:
        'Resign ends this match as your loss and ends the peer session. Continue?',
      battle_confirm_quit_cpu: 'End CPU practice battle?',
      battle_err_peer_id: 'Enter peer ID',
      battle_leave_solo_confirm: 'End solo virtual connection?',
      battle_leave_virtual_confirm:
        'End virtual battle?\n\nThis ends the peer session too.',
      battle_err_lookup_id: 'Enter server ID to look up',
      battle_fullscreen_hint:
        'Battle is fullscreen. End from “End battle” at the top.',
      battle_footer_long:
        'Free battle (practice) vs CPU anytime (no economy). Matched virtual players use the same PHASE A rules. Matchmaking is later.',
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

  /** @param {string} key @param {Record<string, string|number>} [vars] */
  function tf(key, vars) {
    let s = t(key);
    if (vars && typeof vars === 'object') {
      for (const k of Object.keys(vars)) {
        s = String(s).split(`{${k}}`).join(vars[k] == null ? '' : String(vars[k]));
      }
    }
    return s;
  }

  function getLang() {
    return currentLang;
  }

  function applyChrome() {
    document.documentElement.lang = currentLang === 'en' ? 'en' : 'ja';
    document.title = t('doc_title');

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

    document.querySelectorAll('[data-i18n-deck-tooltip]').forEach((el) => {
      const key = el.getAttribute('data-i18n-deck-tooltip');
      if (!key) return;
      el.setAttribute('data-deck-tooltip', t(key));
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
    tf,
    getLang,
    setLang,
    applyChrome,
    onLocaleChange,
  };
})(window);

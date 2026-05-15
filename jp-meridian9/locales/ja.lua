-- ============================================================
-- MERIDIAN-9 / Project JANUS  日本語ロケール
-- ============================================================

Locales = Locales or {}
Locales['ja'] = {
    -- ▼ UI 共通
    ['vega_ui_title'] = 'ヴェガ',

    -- ▼ NPC 対話（旧キー・互換）
    ['npc_greeting_first'] = '……いらっしゃい。法律相談ですか？ それとも——別件で？',
    ['npc_greeting_repeat'] = '……お戻りでしたか。ご用件は？',

    -- ▼ ヴェガ対話（INSTRUCTION-009）
    ['vega_first_greeting'] = '……いらっしゃい。法律相談ですか？ それとも——別件で？',
    ['vega_first_choice_other'] = '別件で来た',
    ['vega_first_choice_legal'] = '法律相談で',
    ['vega_first_choice_wrong'] = '人違いだった',
    ['vega_legal_decline'] = '申し訳ありませんが、当方は現在、新規の法務案件を受け付けておりません。お引き取りを。',
    ['vega_first_how_did_you_know'] = '……どこで聞きましたか',
    ['vega_source_bar'] = '酒場で小耳に挟んだ',
    ['vega_source_friend'] = '知り合いから紹介された',
    ['vega_source_intuition'] = 'ただの勘だ',
    ['vega_first_pitch_1'] = 'そうですか。では、本題に入りましょう。',
    ['vega_first_pitch_2'] = '当方は、ある依頼人の代理として、特殊な調査任務を遂行できる人材を探しています。報酬は高額。一回の任務で、平均的な市民の年収を超える額を提示できる場合もあります。',
    ['vega_first_pitch_3'] = 'ただし、リスクは相応です。任務地は危険で、過去に複数の作業者が帰還していません。当方は安全を保証しません。装備も提供しません。全ては自己責任——契約書にサインする時点で、それに同意していただきます。',
    ['vega_first_pitch_4'] = '興味は、ありますか？',
    ['vega_first_choice_continue'] = '詳しく聞かせてくれ',
    ['vega_first_choice_refuse'] = '危険すぎる、やめておく',
    ['vega_first_refuse_response'] = '賢明な判断です。お引き取りを。',
    ['vega_first_contract_intro'] = '結構です。詳細は契約締結後にお伝えします。契約前に説明できるのは、ここまで。',
    ['vega_first_confidentiality'] = 'ひとつだけ、先に伝えておきます。任務地での出来事を、外部に漏らさないこと。家族、友人、警察、メディア——いかなる相手にも。これは法的拘束力のある守秘義務です。違反者には相応の対応を取らせていただきます。',
    ['vega_first_contract_prompt'] = '……契約しますか？',
    ['vega_first_choice_sign'] = '契約する',
    ['vega_first_choice_think'] = '考えさせてくれ',
    ['vega_first_think_response'] = '結構です。いつでもお越しください。',
    ['vega_first_signed'] = 'ようこそ、JANUS プログラムへ。詳細をご説明します。',
    ['vega_contract_failed'] = '契約処理に失敗しました。サーバー管理者へお問い合わせください。',
    ['vega_tutorial_1'] = '任務地は、ある場所——具体的な地名は申し上げられません。当方ではそこを「サイト・ナイン」と呼称しています。',
    ['vega_tutorial_2'] = '現地には、当方の前任スタッフが残してきた調査資料、機材、サンプルが散在しています。それらを回収し、持ち帰っていただく——これが基本任務です。',
    ['vega_tutorial_3'] = '現地には敵対的存在がいます。人型ですが、人ではありません。詳細は現地で確認してください。武装は推奨します。',
    ['vega_tutorial_4'] = '最大 5 名のチーム編成が可能です。チームメンバーも全員、当方と契約済みである必要があります。未契約者を連れての潜入は認められません。',
    ['vega_tutorial_5'] = '脱出ポイントは現地に複数設置されています。マップ上に表示されます。任務開始後、いつでも撤退可能です。ただし——死亡した場合、所持品は全て失われます。脱出に成功した分のみ、当方が買い取らせていただきます。',
    ['vega_tutorial_6'] = '報酬は、回収物の価値に応じて算定。査定基準は当方の独自判断によります。異議申し立ては受け付けません。',
    ['vega_tutorial_7'] = '……以上です。質問は？',
    ['vega_q_where'] = 'サイト・ナインとはどこだ？',
    ['vega_a_where'] = '申し上げられません。',
    ['vega_q_enemy'] = '敵対的存在とは具体的に何だ？',
    ['vega_a_enemy'] = '現地で確認してください。事前情報は判断を鈍らせます。',
    ['vega_q_staff'] = '前任スタッフはどうなった？',
    ['vega_a_staff'] = '……それも、現地で確認できるかもしれません。',
    ['vega_q_max_reward'] = '報酬の最高額は？',
    ['vega_a_max_reward'] = '過去最高は、一回の任務で 25 万ドル相当でした。その作業者は、二度目の任務で帰還しませんでしたが。',
    ['vega_q_none'] = '質問はない',
    ['vega_tutorial_end'] = '結構です。それでは、いつでもどうぞ。準備が整いましたら、再度お越しください。地下にゲートを用意しています。',
    ['vega_repeat_greeting'] = '……お戻りでしたか。ご用件は？',
    ['vega_repeat_start_mission'] = 'ゲートを起動してくれ',
    ['vega_repeat_sell'] = '回収物を売却したい',
    ['vega_repeat_sell_sub'] = '※ INSTRUCTION-015 で実装予定',
    ['vega_repeat_sell_wip'] = '（売却機能は準備中です）',
    ['vega_repeat_info'] = '最近、何か情報は？',
    ['vega_repeat_leave'] = '帰る',
    ['vega_repeat_leave_response'] = 'お気をつけて。',
    ['vega_gate_party_prompt'] = '了解しました。同行者を指定してください。契約済みの者のみ選択可能です。',
    ['vega_gate_confirm'] = '全員、契約は確認できました。地下へどうぞ。ゲートは 30 秒後に起動します。',
    ['vega_gate_final'] = '——生きて戻ってきてください。それが、当方からの唯一の願いです。',
    ['vega_return_greeting'] = 'お帰りなさい。全員、無事のようで何より。',
    ['vega_return_partial'] = '……何名か、戻られませんでしたね。契約書通り、遺族への通知と補償は当方で処理します。ご心配なく。',
    ['vega_return_appraise'] = '回収物を拝見します。',
    ['vega_return_payment'] = '査定額は $%s です。即時、ご指定の口座に振り込みます。お疲れ様でした。',
    ['vega_return_next'] = 'また、お待ちしています。',
    ['vega_flavor_none'] = '……特に新しい情報はありません。',
    ['vega_target_label'] = 'ヴェガと話す',

    -- ▼ ブリップ（INSTRUCTION-010）
    ['npc_blip_label'] = 'Vega & Associates 法律事務所',

    -- ▼ ゲート選択肢
    ['gate_solo'] = 'ソロで行く',
    ['gate_solo_desc'] = '一人でゲートを開いて出発します',
    ['gate_party'] = 'パーティを編成する',
    ['gate_party_desc'] = '最大5人までのパーティを編成します',

    -- ▼ パーティ UI / 通知
    ['party_menu_title'] = 'パーティ編成',
    ['party_member_list'] = 'メンバー (%d/%d)',
    ['party_invite_nearby'] = '近くのプレイヤーを招待',
    ['party_no_nearby_players'] = '近くに招待可能なプレイヤーがいません',
    ['party_kick_member'] = 'メンバーを追放',
    ['party_kick_select'] = '追放するメンバーを選択',
    ['party_disband'] = 'パーティを解散',
    ['party_leave'] = 'パーティを離脱',
    ['party_confirm_dispatch'] = 'ゲートを開いて出発',
    ['party_close_menu'] = '閉じる',
    ['party_invite_received_header'] = 'パーティ招待',
    ['party_invite_received'] = '%s からパーティ招待が届きました',
    ['party_invite_accept'] = '承諾',
    ['party_invite_decline'] = '拒否',
    ['party_invite_sent'] = '%s に招待を送信しました',
    ['party_invite_accepted'] = '%s が招待を承諾しました',
    ['party_invite_declined'] = '%s が招待を拒否しました',
    ['party_invite_timeout'] = '招待がタイムアウトしました',
    ['party_member_joined'] = '%s がパーティに加入しました',
    ['party_member_left'] = '%s がパーティを離脱しました',
    ['party_member_kicked'] = '%s がパーティから追放されました',
    ['party_leader_promoted'] = '%s が新しいリーダーになりました',
    ['party_disbanded'] = 'パーティが解散されました',
    ['party_dispatched'] = 'ゲートを開きました。転送します……',
    ['party_you_were_kicked'] = 'パーティから追放されました',

    ['err_not_leader'] = 'リーダーのみが実行できます',
    ['err_already_in_party'] = '既にパーティに参加しています',
    ['err_not_in_party'] = 'パーティに所属していません',
    ['err_target_in_party'] = '対象は既に他のパーティに参加しています',
    ['err_target_in_session'] = '対象は既にミッション中です',
    ['err_target_not_contracted'] = '対象は契約者ではありません',
    ['err_target_too_far'] = '対象が招待範囲外です',
    ['err_party_full'] = 'パーティは満員です',
    ['err_party_too_few'] = 'メンバーが不足しています',
    ['err_no_pending_invite'] = '保留中の招待がありません',
    ['err_invite_expired'] = '招待が期限切れです',
    ['err_target_offline'] = '対象がオフラインです',
    ['err_invite_pending_elsewhere'] = '対象は既に他パーティからの招待保留中です',
    ['err_pending_invites'] = '未処理の招待があるため出発できません',
    ['err_session_create_failed'] = 'セッション作成に失敗しました: %s',
    ['err_unknown'] = '不明なエラーが発生しました',

    -- Session.Create 失敗コード（表示用）
    ['member_not_contracted'] = 'メンバーに契約未締結者が含まれています',
    ['member_already_in_session'] = 'メンバーが既に他セッションに所属しています',
    ['invalid_member'] = '無効なメンバーが含まれています',
    ['invalid_params'] = 'セッション引数が不正です',
    ['too_many_sessions'] = '同時セッション上限に達しています',
    ['no_bucket_available'] = 'ルーティングバケットが枯渇しています',
    ['no_spawn_point'] = 'スポーン地点が未設定です（Config.Mission.spawnPoint）',
    ['session_not_found'] = 'セッションが見つかりません',

    -- ▼ パーティ（旧キー互換）
    ['party_invite_rejected'] = '招待を拒否しました',

    -- ▼ ミッション
    ['mission_starting'] = 'ゲートが起動します……',
    ['mission_started'] = 'サイト・ナインへようこそ',
    ['mission_timeout'] = '制限時間に到達しました。強制撤収します',
    ['mission_wipe'] = '全滅。任務は失敗しました',

    -- ▼ ゾンビアリーナ（INSTRUCTION-011）
    ['arena_countdown'] = 'ウェーブ開始まで %d 秒',
    ['arena_wave_start'] = 'ウェーブ %d / %d — 敵 %d 体',
    ['arena_wave_cleared'] = 'ウェーブ %d クリア。次まで %d 秒',
    ['arena_mission_failed'] = '全滅。サイト・ナインから送還されました',
    ['arena_mission_success'] = 'サイト・ナインの脅威を退けた',

    -- ▼ ルート（INSTRUCTION-012）
    ['loot_pickup_label'] = '回収する',
    ['loot_pickup_ok'] = '%s を取得（所持 %d）',
    ['loot_err_too_far'] = '距離が遠すぎます',
    ['loot_err_not_found'] = 'この回収物は既にないか無効です',
    ['loot_err_cooldown'] = '操作が早すぎます',
    ['loot_err_no_session'] = '任務セッション外です',
    ['loot_err_not_member'] = 'パーティに含まれていません',
    ['loot_err_no_ped'] = 'プレイヤー状態が不正です',
    ['loot_err_bad_item'] = 'アイテム定義エラー',
    ['loot_err_invalid_args'] = '引数が不正です',
    ['loot_err_unknown'] = '回収に失敗しました',

    -- ▼ 脱出
    ['extract_available'] = '[E] を長押しで脱出',
    ['extract_in_progress'] = '脱出中……動かないでください',
    ['extract_success'] = '脱出に成功しました',

    -- ▼ 報酬
    ['reward_received'] = '報酬 $%d を受け取りました',
    ['reward_total_value'] = '回収物総額: $%d',

    -- ▼ システム
    ['contract_required'] = '先にヴェガと契約を結ぶ必要があります',
    ['contract_signed'] = '契約が締結されました。JANUS プログラムへようこそ',
    ['debug_only'] = 'このコマンドはデバッグモード時のみ使用可能です',
}

--- フレーバーセリフ（`_()` 非対象・テーブル参照）
Locales['ja'].vega_flavor = {
    '……前回の作業者が、向こうで動いている自分の影を二つ見たと報告していました。鏡はなかったそうです。',
    'ゲートのエネルギー反応が、ここ三日ほど不安定です。何かが向こうで活発化している可能性があります。',
    'ある作業者が持ち帰ったサンプルが、保管庫の中で勝手に容器の位置を変えていたと報告がありました。現在、別室で隔離中です。',
    '上層部からの指示で、回収優先度の高いアイテムリストが更新されました。後ほどお渡しします。',
    '向こうで死亡した前任研究員の遺族には、「海外赴任中の事故」として処理しています。胸糞悪い話ですが、それが当方の仕事です。',
    '先週、ある作業者が自分以外、誰も気づかない人影を現地で見たと言っていました。翌週の任務には現れませんでした。',
    '最近、警察関係者が当事務所周辺を嗅ぎ回っているようです。もし職務質問された場合は、法律相談で来訪した、とだけ答えてください。',
    'Subject-0 という呼称を、もし現地で目にすることがあれば——即座に撤退してください。これは推奨ではなく、警告です。',
    'ある回収物の解析結果が、当方の物理学者を三日間眠れなくさせました。詳細は、お伝えできません。',
    '……あなたは、私が今まで会った中で、最も長く生き残っている契約者の一人です。それを誇りに思うべきか、不気味に思うべきか——判断はお任せします。',
}

---@param key string
---@param ... any
---@return string
function _(key, ...)
    local locale = Config and Config.Locale or 'ja'
    local pack = Locales[locale] or Locales['ja']
    local str = pack and pack[key] or key
    if type(str) ~= 'string' then
        return tostring(key)
    end
    if select('#', ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

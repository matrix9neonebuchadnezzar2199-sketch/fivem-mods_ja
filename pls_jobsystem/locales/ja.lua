-- pls_jobsystem 日本語ロケール
-- Source: https://github.com/polisek/pls_jobsystem (MIT)
-- Maintainer: matrix9neonebuchadnezzar2199-sketch

Locales = Locales or {}

Locales["ja"] = {
    -- Crafting
    crafting_progress = "%s を作成中…",
    not_enough_items = "必要な材料が揃っていません！",
    recipe_created = "新しいレシピを作成しました！",
    item_deleted = "アイテムを削除しました。",

    -- Cash Register
    withdraw_success = "引き出しに成功しました！",
    withdraw_fail = "引き出せませんでした。",
    deposit_success = "預け入れに成功しました！",
    deposit_fail = "所持金が不足しています。",

    -- Jobs
    job_created = "新しいジョブを作成しました！",
    job_saved = "ジョブを保存しました！",
    job_deleted = "ジョブを削除しました！",
    job_not_found = "このジョブは存在しません！",
    not_your_job = "あなたのジョブではありません。",

    -- Creative
    select_point = "[ E ] で位置を確定",
    backup_created = "バックアップを作成しました！",
    backup_restored = "バックアップから復元しました！",

    -- Stashes
    stash_deleted = "スタッシュを削除しました！",

    -- Peds
    ped_deleted = "NPCを削除しました！",

    -- General
    confirm_delete = "本当に削除してもよろしいですか？",
    confirm_action = "本当に実行してもよろしいですか？",
    success = "成功",
    error = "エラー",

    -- 追加（ハードコード除去）
    model_not_found = "モデルが見つかりません: %s",
    no_recipes = "この作業台にはレシピがありません。",
    cannot_use = "これは使用できません。",
    missing_ingredient = "%s が不足しています",
    label_recipe = "レシピ",
    label_cash_register = "レジ",
    label_alarm = "アラーム",
    label_call_police = "警察を呼ぶ",
    label_boss_menu = "ボスメニュー",
    call_police_confirm = "本当に警察を呼びますか？",
    job_created_title = "完了",
    job_create_fail_title = "おや？",
    job_create_fail_desc = "このジョブは誰かに削除された可能性があります。",
    job_title = "ジョブ",
    shop_title = "ショップ",
    backup_title = "バックアップ",
    crafting_title = "クラフト",
    withdraw_title = "引き出し",
    deposit_title = "預け入れ",
    withdraw_done = "処理しました",
    deposit_done = "処理しました",
    backup_done_title = "バックアップ完了",
    backup_done_desc = "バックアップを取りました。安心して編集できます。",
    shop_purchase_ok = "%dx %s（計 $%d）",
    shop_not_enough = "お金が足りません！",
    crafting_result = "%dx %s を作成しました",
    ic_prompt_use = "[E] %s を使う",

    gizmo_hint = "[E] 確定  [X] キャンセル\n[Q] -%s° ↺  [R] +%s° ↻  [G] 軸: %s\n[Scroll] 高さ: %.2f m  [Shift] 精密 (%s)",

    cmd_createjob = "ジョブ作成UIを開く（管理者）",
    cmd_open_jobs = "ジョブ編集メニューを開く（管理者）",
}

Config = {}

Config.Command = 'card'             -- コマンド名
Config.DisplayTime = 3000           -- カード表示時間（ミリ秒）
Config.Cooldown = 3                 -- 連打防止クールダウン（秒）
Config.ChatRange = 30.0             -- チャット通知が届く範囲（メートル）
Config.ShowChatMessage = true       -- チャットにも結果を表示するか

-- カードデッキ定義（54枚：52枚 + ジョーカー2枚）
Config.Suits = {
    { name = 'スペード', symbol = '♠', color = 'black' },
    { name = 'ハート', symbol = '♥', color = 'red' },
    { name = 'ダイヤ', symbol = '♦', color = 'red' },
    { name = 'クラブ', symbol = '♣', color = 'black' },
}

Config.Ranks = {
    { name = 'A', display = 'A' },
    { name = '2', display = '2' },
    { name = '3', display = '3' },
    { name = '4', display = '4' },
    { name = '5', display = '5' },
    { name = '6', display = '6' },
    { name = '7', display = '7' },
    { name = '8', display = '8' },
    { name = '9', display = '9' },
    { name = '10', display = '10' },
    { name = 'J', display = 'J' },
    { name = 'Q', display = 'Q' },
    { name = 'K', display = 'K' },
}

-- ジョーカー
Config.Jokers = {
    { name = 'ジョーカー（赤）', symbol = '🃏', color = 'red' },
    { name = 'ジョーカー（黒）', symbol = '🃏', color = 'black' },
}

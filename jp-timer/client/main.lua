-- コマンド登録: /min [分数]
RegisterCommand('min', function(_source, args)
    local minutes = tonumber(args[1])
    if not minutes or minutes <= 0 or minutes > 60 then
        TriggerEvent('chat:addMessage', {
            args = { '^1[タイマー]', '1〜60の数字を指定してください（例: /min 3）' },
        })
        return
    end

    SetNuiFocus(false, false)
    SendNUIMessage({
        type = 'startTimer',
        minutes = minutes,
    })
end, false)

-- タイマーキャンセル: /minstop
RegisterCommand('minstop', function()
    SendNUIMessage({
        type = 'stopTimer',
    })
end, false)

-- チャット候補表示
TriggerEvent('chat:addSuggestion', '/min', 'カウントダウンタイマー開始', {
    { name = '分', help = '分数を指定（例: 1, 3, 5）' },
})
TriggerEvent('chat:addSuggestion', '/minstop', 'タイマーを停止')

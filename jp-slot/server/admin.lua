-- 管理者コマンド・権限チェック

--- ACE で管理者かどうか
---@param source number
---@return boolean
local function isAdmin(source)
    if source == 0 then
        return true
    end
    return IsPlayerAceAllowed(source, Config.AdminAce or 'jp-slot.admin')
end

---@param source number
---@param msg string
local function notifyError(source, msg)
    TriggerClientEvent('chat:addMessage', source, {
        color = { 255, 80, 80 },
        multiline = true,
        args = { '[jp-slot]', tostring(msg) },
    })
end

RegisterCommand(Config.AdminCommand or 'jpslotadmin', function(source, _args, _raw)
    if source == 0 then
        print('[jp-slot] コンソールからは管理NUIを開けません（ゲーム内プレイヤーで実行）。')
        return
    end
    if not isAdmin(source) then
        return
    end
    local theme = Theme.getActive()
    TriggerClientEvent('jp-slot:openAdmin', source, {
        theme = theme,
        debug = Config.Debug,
        showDebugTab = Config.Debug and Config.DebugSettings and Config.DebugSettings.ShowDebugButtons,
        uiSize = JpSlotGetUISize(),
    })
end, false)

RegisterNetEvent('jp-slot:admin:setUISize', function(data)
    local src = source
    if not isAdmin(src) then
        notifyError(src, '権限がありません')
        return
    end
    if type(data) ~= 'table' then
        return
    end
    local size = {
        widthPercent = math.max(30, math.min(100, tonumber(data.widthPercent) or 90)),
        heightPercent = math.max(30, math.min(100, tonumber(data.heightPercent) or 90)),
        maxWidthPx = math.max(0, math.min(7680, tonumber(data.maxWidthPx) or 0)),
    }
    SetResourceKvp('jp-slot:ui_size', json.encode(size))
    TriggerClientEvent('jp-slot:applyUISize', -1, size)
    print(('[jp-slot] UISize updated by %s: %d%% x %d%% (maxWidthPx=%d)'):format(
        GetPlayerName(src) or tostring(src),
        size.widthPercent,
        size.heightPercent,
        size.maxWidthPx
    ))
end)

RegisterNetEvent('jp-slot:admin:resetUISize', function()
    local src = source
    if not isAdmin(src) then
        notifyError(src, '権限がありません')
        return
    end
    DeleteResourceKvp('jp-slot:ui_size')
    local size = {
        widthPercent = Config.UISize.widthPercent or 90,
        heightPercent = Config.UISize.heightPercent or 90,
        maxWidthPx = Config.UISize.maxWidthPx or 0,
    }
    TriggerClientEvent('jp-slot:applyUISize', -1, size)
    print(('[jp-slot] UISize reset to defaults by %s'):format(GetPlayerName(src) or tostring(src)))
end)

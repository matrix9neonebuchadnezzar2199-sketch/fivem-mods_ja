---@diagnostic disable: undefined-global

local uiOpen = false

---NUI を閉じてフォーカス解除
local function closeUi()
    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setState', state = 'hidden' })
end

---作成結果（サーバーまたはローカル検証）
---@param ok boolean
local function applyCreateResult(ok)
    if ok then
        closeUi()
    end
end

---NUI を表示
---@param payload table
local function openUi(payload)
    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage(payload)
end

---空 DVD（items.lua の export）
exports('useBlank', function(_, _)
    if uiOpen then return end
    openUi({ action = 'openCreate' })
end)

---データ入り DVD
exports('useRecorded', function(_, slot)
    if uiOpen then return end
    local meta = (slot and slot.metadata) or {}
    local title = type(meta.title) == 'string' and meta.title or ''
    local url = type(meta.url) == 'string' and meta.url or ''
    openUi({ action = 'openPlayer', title = title, url = url })
end)

RegisterNUICallback('save', function(data, cb)
    local title = data and data.title
    local url = data and data.url
    if type(title) ~= 'string' or type(url) ~= 'string' then
        cb('ok')
        return
    end
    title = title:gsub('^%s+', ''):gsub('%s+$', '')
    url = url:gsub('^%s+', ''):gsub('%s+$', '')
    local tlen = utf8.len(title)
    if title == '' or url == '' or not tlen or tlen < 1 or tlen > Config.MaxTitleLength then
        applyCreateResult(false)
        cb('ok')
        return
    end
    TriggerServerEvent('dvd-maker:server:create', title, url)
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb('ok')
end)

RegisterNUICallback('playbackEnded', function(_, cb)
    cb('ok')
end)

RegisterNetEvent('dvd-maker:client:createResult', applyCreateResult)

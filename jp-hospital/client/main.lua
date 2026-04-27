-- jp-hospital クライアント: NPC, ox_target, NUI
local localPed = 0
local nuiOpen = false
local jobActive = false
--- 難易度を選ぶ前（勤務未開始）なら ESC も日報にしない
local awaitingDifficulty = false
--- 表示用集計（サーバーの値を優先）
local currentCombo = 0
local maxComboD = 0
local karteCleared = 0
local totalRewardD = 0

local function nui(f)
    SetNuiFocus(f, f)
end

local function sendToNui(etype, pl)
    SendNUIMessage({
        type = etype,
        payload = pl,
    })
end

-- 難易度未選択のまま閉じる（サーバー未開始＝日報不要）
local function closeNuiWithoutShift()
    awaitingDifficulty = false
    nuiOpen = false
    jobActive = false
    nui(false)
    sendToNui('forceClose', {})
end

-- 退勤: サーバーに集計依頼 → 日報を受信してからフォーカス・表示を制御
local function requestEndShift()
    if not nuiOpen then
        return
    end
    if awaitingDifficulty then
        closeNuiWithoutShift()
        return
    end
    jobActive = false
    sendToNui('jobEnding', {})
    TriggerServerEvent('jp-hospital:endShift')
end

local function openJobNui()
    if nuiOpen then
        return
    end
    nuiOpen = true
    jobActive = true
    awaitingDifficulty = false
    currentCombo = 0
    maxComboD = 0
    karteCleared = 0
    totalRewardD = 0
    nui(true, true)
    local difflist = {}
    for _, d in ipairs(Config.Difficulties or {}) do
        if d and d.id then
            difflist[#difflist + 1] = {
                id = d.id,
                label = d.label or d.id,
                description = d.description or '',
            }
        end
    end
    if #difflist < 1 then
        sendToNui('open', { difficulties = {} })
        TriggerServerEvent('jp-hospital:startShift', 'easy')
    else
        awaitingDifficulty = true
        sendToNui('open', { difficulties = difflist })
    end
end

RegisterNUICallback('hospitalKarteSubmit', function(data, cb)
    cb('ok')
    TriggerServerEvent('jp-hospital:karteComplete', {
        sessionId = data and data.sessionId,
        selectedIds = data and data.selectedIds,
    })
end)

RegisterNUICallback('hospitalRequestNextKarte', function(_, cb)
    cb('ok')
    TriggerServerEvent('jp-hospital:requestKarte')
end)

RegisterNUICallback('hospitalDifficultyCancel', function(_, cb)
    cb('ok')
    if not nuiOpen then
        return
    end
    closeNuiWithoutShift()
end)

RegisterNUICallback('hospitalSelectDifficulty', function(data, cb)
    cb('ok')
    local id = 'easy'
    if type(data) == 'string' and data ~= '' then
        local ok, t = pcall(function()
            return json.decode(data)
        end)
        if ok and type(t) == 'table' and t.id then
            id = tostring(t.id)
        end
    elseif type(data) == 'table' and data and data.id then
        id = tostring(data.id)
    end
    TriggerServerEvent('jp-hospital:startShift', id)
end)

RegisterNetEvent('jp-hospital:shiftStartFailed', function(p)
    if not nuiOpen then
        return
    end
    sendToNui('shiftStartFailed', p or {})
end)

RegisterNetEvent('jp-hospital:shiftStarted', function()
    if not nuiOpen then
        return
    end
    awaitingDifficulty = false
    sendToNui('beginGame', {})
    Wait(100)
    TriggerServerEvent('jp-hospital:requestKarte')
end)

RegisterNUICallback('hospitalEndShift', function(_, cb)
    cb('ok')
    requestEndShift()
end)

RegisterNUICallback('hospitalCloseNui', function(_, cb)
    cb('ok')
    requestEndShift()
end)

RegisterNetEvent('jp-hospital:receiveKarte', function(data)
    if not nuiOpen then
        return
    end
    if type(data) == 'table' and data.totalReward then
        totalRewardD = data.totalReward
    end
    if type(data) == 'table' and data.combo then
        currentCombo = data.combo
    end
    if type(data) == 'table' and data.maxCombo then
        maxComboD = data.maxCombo
    end
    if type(data) == 'table' and data.karteCount then
        karteCleared = data.karteCount
    end
    sendToNui('karteData', data)
end)

RegisterNetEvent('jp-hospital:verifyResult', function(res)
    if not nuiOpen then
        return
    end
    if type(res) == 'table' and res.totalReward then
        totalRewardD = res.totalReward
    end
    if type(res) == 'table' and res.combo then
        currentCombo = res.combo
    end
    if type(res) == 'table' and res.maxCombo then
        maxComboD = res.maxCombo
    end
    if type(res) == 'table' and res.ok then
        if res.reward then
            totalRewardD = (tonumber(res.totalReward) or totalRewardD)
        end
    end
    sendToNui('verify', res)
end)

RegisterNetEvent('jp-hospital:verifyFail', function(_)
    if not nuiOpen then
        return
    end
    sendToNui('verify', { ok = false, reason = 'bad' })
end)

RegisterNetEvent('jp-hospital:dayReport', function(rep)
    jobActive = false
    nuiOpen = true
    nui(true, true)
    sendToNui('dayReport', rep or {})
end)

-- 日報を閉じる
RegisterNUICallback('hospitalDayReportClose', function(_, cb)
    cb('ok')
    nui(false)
    nuiOpen = false
    sendToNui('dayReportClose', {})
end)

CreateThread(function()
    local c = Config.JobPedCoords
    if not c then
        return
    end
    local m = (Config.JobPedModel) or 's_m_m_doctor_01'
    local h = GetHashKey(m)
    RequestModel(h)
    local t0 = GetGameTimer()
    while not HasModelLoaded(h) and (GetGameTimer() - t0) < 15000 do
        Wait(100)
    end
    if not HasModelLoaded(h) then
        if Config.Debug then
            print('[jp-hospital] モデル読み込み失敗 ' .. m)
        end
        return
    end
    local ped = CreatePed(0, h, c.x, c.y, c.z - 1.0, c.w, false, true)
    if ped and ped ~= 0 then
        SetEntityAsMissionEntity(ped, true, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        localPed = ped
        local sc = (Config.JobPedScenario) or 'WORLD_HUMAN_CLIPBOARD'
        if sc and sc ~= '' then
            TaskStartScenarioInPlace(ped, sc, 0, true)
        end
    end
    SetModelAsNoLongerNeeded(h)
    for _i = 1, 30 do
        if localPed ~= 0 and GetResourceState('ox_target') == 'started' then
            break
        end
        Wait(300)
    end
    if localPed ~= 0 and GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(localPed, {
            {
                name = 'jp-hospital:job',
                label = 'カルテ整理（内職）',
                icon = 'fa-solid fa-briefcase-medical',
                distance = Config.InteractRadius or 2.0,
                onSelect = function()
                    openJobNui()
                end,
            },
        })
    end
end)

RegisterCommand((Config.ExitCommand) or 'hospital', function()
    if nuiOpen and jobActive then
        requestEndShift()
    end
end, false)

-- ESC: 勤務中は退勤＝日報へ / 日報表示中は閉じる
CreateThread(function()
    while true do
        if nuiOpen then
            if IsControlJustPressed(0, 322) then
                if jobActive then
                    requestEndShift()
                else
                    SendNUIMessage({ type = 'dayReportEsc' })
                end
                Wait(300)
            else
                Wait(0)
            end
        else
            Wait(400)
        end
    end
end)

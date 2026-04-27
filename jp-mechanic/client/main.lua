-- jp-mechanic: NPC, E / ox_target, NUI
local localPed = 0
local nuiOpen = false
local jobActive = false
local awaitingDifficulty = false

-- 日報はマウス操作も有効化したいため第2引数可
local function nui(focusKeyboard, focusCursor)
    if focusCursor == nil then
        focusCursor = focusKeyboard
    end
    SetNuiFocus(focusKeyboard, focusCursor)
end

local function sendToNui(etype, pl)
    SendNUIMessage({
        type = etype,
        payload = pl,
    })
end

local function closeNuiWithoutShift()
    awaitingDifficulty = false
    nuiOpen = false
    jobActive = false
    nui(false)
    sendToNui('forceClose', {})
end

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
    TriggerServerEvent('jp-mechanic:endShift')
end

local function openJobNui()
    if nuiOpen then
        return
    end
    nuiOpen = true
    jobActive = true
    awaitingDifficulty = false
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
        TriggerServerEvent('jp-mechanic:startShift', 'easy')
    else
        awaitingDifficulty = true
        sendToNui('open', { difficulties = difflist })
    end
end

RegisterNUICallback('mechanicKarteSubmit', function(data, cb)
    cb('ok')
    TriggerServerEvent('jp-mechanic:slipComplete', {
        sessionId = data and data.sessionId,
        selectedIds = data and data.selectedIds,
    })
end)

RegisterNUICallback('mechanicRequestNextKarte', function(_, cb)
    cb('ok')
    TriggerServerEvent('jp-mechanic:requestSlip')
end)

RegisterNUICallback('mechanicDifficultyCancel', function(_, cb)
    cb('ok')
    if nuiOpen then
        closeNuiWithoutShift()
    end
end)

RegisterNUICallback('mechanicSelectDifficulty', function(data, cb)
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
    TriggerServerEvent('jp-mechanic:startShift', id)
end)

RegisterNetEvent('jp-mechanic:shiftStartFailed', function(p)
    if nuiOpen then
        sendToNui('shiftStartFailed', p or {})
    end
end)

RegisterNetEvent('jp-mechanic:shiftStarted', function()
    if not nuiOpen then
        return
    end
    awaitingDifficulty = false
    sendToNui('beginGame', {})
    Wait(100)
    TriggerServerEvent('jp-mechanic:requestSlip')
end)

RegisterNUICallback('mechanicEndShift', function(_, cb)
    cb('ok')
    requestEndShift()
end)

RegisterNUICallback('mechanicCloseNui', function(_, cb)
    cb('ok')
    requestEndShift()
end)

RegisterNetEvent('jp-mechanic:receiveSlip', function(data)
    if nuiOpen then
        sendToNui('karteData', data)
    end
end)

RegisterNetEvent('jp-mechanic:verifyResult', function(res)
    if nuiOpen then
        sendToNui('verify', res)
    end
end)

RegisterNetEvent('jp-mechanic:verifyFail', function()
    if nuiOpen then
        sendToNui('verify', { ok = false, reason = 'bad' })
    end
end)

RegisterNetEvent('jp-mechanic:dayReport', function(rep)
    jobActive = false
    nuiOpen = true
    nui(true, true)
    sendToNui('dayReport', rep or {})
end)

RegisterNUICallback('mechanicDayReportClose', function(_, cb)
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
    local m = (Config.JobPedModel) or 's_m_m_autoshop_01'
    local h = GetHashKey(m)
    RequestModel(h)
    local t0 = GetGameTimer()
    while not HasModelLoaded(h) and (GetGameTimer() - t0) < 15000 do
        Wait(100)
    end
    if not HasModelLoaded(h) then
        if Config.Debug then
            print('[jp-mechanic] モデル失敗 ' .. m)
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
        local sc = (Config.JobPedScenario) or 'WORLD_HUMAN_HAMMERING'
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
                name = 'jp-mechanic:job',
                label = '伝票整理（内職）',
                icon = 'fa-solid fa-wrench',
                distance = Config.InteractRadius or 2.0,
                onSelect = function()
                    openJobNui()
                end,
            },
        })
    end
end)

-- E キー近接
CreateThread(function()
    while true do
        if localPed and localPed ~= 0 and nuiOpen == false and (Config.UseEKey ~= false) then
            local p = GetEntityCoords(PlayerPedId())
            local c = GetEntityCoords(localPed)
            local d = #(p - c)
            if d < (Config.InteractRadius or 2.0) + 0.3 then
                if IsControlJustPressed(0, 38) then
                    openJobNui()
                    Wait(500)
                else
                    Wait(0)
                end
            else
                Wait(400)
            end
        else
            Wait(500)
        end
    end
end)

RegisterCommand((Config.ExitCommand) or 'mechjob', function()
    if nuiOpen and jobActive then
        requestEndShift()
    end
end, false)

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

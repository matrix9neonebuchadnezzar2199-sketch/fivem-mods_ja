-- ============================================================
-- jp-meridian9 / client/result.lua
-- ============================================================
-- 任務リザルト NUI（サブフェーズ B-b）。`index.html` 内 #mrd9-result-root と連携。
-- ============================================================

local isOpen = false

--- リザルト表示中は右クリック等がゲーム側の照準／発砲に流れてしまうため抑止する。
local function startResultInputGuard()
    CreateThread(function()
        while isOpen do
            pcall(function()
                DisablePlayerFiring(PlayerId(), true)
            end)
            DisableControlAction(0, 24, true) -- INPUT_ATTACK
            DisableControlAction(0, 25, true) -- INPUT_AIM
            DisableControlAction(0, 257, true) -- INPUT_ATTACK2
            DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1
            DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
            DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
            DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
            Wait(0)
        end
    end)
end

local function sendShow(payload)
    if type(payload) == 'table' and type(payload.items) == 'table' then
        for _idx, it in ipairs(payload.items) do
            if type(it) == 'table' and type(it.nameKey) == 'string' and it.nameKey ~= '' then
                it.label = _(it.nameKey)
            end
        end
    end
    SendNUIMessage({
        type = 'result:show',
        payload = type(payload) == 'table' and payload or {},
    })
end

local function openResultNui(payload)
    if isOpen then
        sendShow(payload)
        return
    end
    isOpen = true
    SetNuiFocus(true, true)
    sendShow(payload)
    startResultInputGuard()
end

RegisterNetEvent('jp-meridian9:client:result:show', function(payload)
    openResultNui(payload)
end)

RegisterNetEvent('jp-meridian9:client:result:hide', function()
    if not isOpen then
        return
    end
    SendNUIMessage({ type = 'result:hide' })
    SetNuiFocus(false, false)
    isOpen = false
    if MRD9.RunPostExtractReturnIfPending then
        MRD9.RunPostExtractReturnIfPending()
    end
    pcall(function()
        DisplayRadar(true)
    end)
end)

RegisterNUICallback('result:close', function(_, cb)
    if isOpen then
        SetNuiFocus(false, false)
        isOpen = false
    end
    if MRD9.RunPostExtractReturnIfPending then
        MRD9.RunPostExtractReturnIfPending()
    end
    pcall(function()
        DisplayRadar(true)
    end)
    cb({ ok = true })
end)

--- 移行期間: 旧 `showDialog`（Markdown）と新 NUI payload の両対応
RegisterNetEvent('jp-meridian9:client:result:showDialog', function(payload)
    if type(payload) ~= 'table' then
        return
    end
    if type(payload.result) == 'string' or type(payload.breakdown) == 'table' or type(payload.items) == 'table' then
        openResultNui(payload)
        return
    end
    if type(payload.content) == 'string' and lib and lib.alertDialog then
        lib.alertDialog({
            header = payload.title or 'JANUS',
            content = payload.content,
            centered = true,
            cancel = false,
            labels = { confirm = '了解' },
        })
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    if isOpen then
        SendNUIMessage({ type = 'result:hide' })
        SetNuiFocus(false, false)
        isOpen = false
    end
    if MRD9.RunPostExtractReturnIfPending then
        MRD9.RunPostExtractReturnIfPending()
    end
    pcall(function()
        DisplayRadar(true)
    end)
end)

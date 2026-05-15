local resName = GetCurrentResourceName()

print(('[%s] resource loaded'):format(resName))

MRD9.CurrentSession = nil

RegisterNetEvent('jp-meridian9:onMissionStart', function(data)
    if type(data) ~= 'table' or not data.sessionId then
        return
    end
    MRD9.Log('Mission started: %s', data.sessionId)
    MRD9.CurrentSession = data
    if MRD9.Arena and MRD9.Arena.ClientBeginMission then
        MRD9.Arena.ClientBeginMission()
    end
end)

RegisterNetEvent('jp-meridian9:onMissionEnd', function(data)
    if type(data) ~= 'table' or not data.sessionId then
        return
    end
    local reason = data.reason
    MRD9.Log('Mission ended: %s reason=%s', data.sessionId, tostring(reason))
    MRD9.CurrentSession = nil
    if reason == 'arena_wiped' then
        CreateThread(function()
            Wait(0)
            local ped = PlayerPedId()
            if not ped or ped == 0 then
                return
            end
            local cfg = Config.Arena
            local h = cfg and tonumber(cfg.knockdownHealth) or 1
            local ms = cfg and tonumber(cfg.ragdollDurationMs) or 5000
            SetEntityHealth(ped, h)
            SetPedToRagdoll(ped, ms, ms + 1, 0, true, true, false)
        end)
    end
end)

RegisterNetEvent('jp-meridian9:notify', function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, true)
end)

local function registerCmd(name, handler)
    if type(name) == 'string' and name ~= '' then
        RegisterCommand(name, handler, false)
    end
end

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    SetNuiFocus(false, false)
end)

CreateThread(function()
    local c = Config.Commands
    if not c then
        return
    end
    registerCmd(c.stats, function()
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName('MERIDIAN-9: 統計表示は未実装（ロードマップ INSTRUCTION-006 以降）')
        EndTextCommandThefeedPostTicker(false, true)
    end)
    if Config.Debug and c.debugTeleport then
        registerCmd(c.debugTeleport, function()
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName('MERIDIAN-9: デバッグ転送は未実装')
            EndTextCommandThefeedPostTicker(false, true)
        end)
    end
end)

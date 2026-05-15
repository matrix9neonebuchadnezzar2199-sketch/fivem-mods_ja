local resName = GetCurrentResourceName()

print(('[%s] resource loaded'):format(resName))

MRD9.CurrentSession = nil

RegisterNetEvent('jp-meridian9:onMissionStart', function(data)
    if type(data) ~= 'table' or not data.sessionId then
        return
    end
    MRD9.Log('Mission started: %s', data.sessionId)
    MRD9.CurrentSession = data
end)

RegisterNetEvent('jp-meridian9:onMissionEnd', function(data)
    if type(data) ~= 'table' or not data.sessionId then
        return
    end
    MRD9.Log('Mission ended: %s reason=%s', data.sessionId, tostring(data.reason))
    MRD9.CurrentSession = nil
end)

RegisterNetEvent('jp-meridian9:notify', function(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(tostring(msg))
    EndTextCommandThefeedPostTicker(false, true)
end)

RegisterNetEvent('jp-meridian9:client:openPartyMenu', function()
    lib.notify({
        title = _('party_menu_wip_title'),
        description = _('party_menu_wip_desc'),
        type = 'inform',
    })
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

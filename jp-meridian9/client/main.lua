local resName = GetCurrentResourceName()

print(('[%s] resource loaded'):format(resName))

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

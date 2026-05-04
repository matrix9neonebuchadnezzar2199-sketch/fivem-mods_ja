-- フレームワーク抽象化（ESX / QB-Core / Qbox）。サーバー主用途。クライアントでは検出のみ。

FW = FW or {}
FW.name = FW.name or nil
FW.object = FW.object or nil

CreateThread(function()
    if Config.Framework == "auto" then
        if GetResourceState('qbx_core') == 'started' then
            FW.name = 'qbox'
        elseif GetResourceState('es_extended') == 'started' then
            FW.name = 'esx'
        elseif GetResourceState('qb-core') == 'started' then
            FW.name = 'qbcore'
        else
            FW.name = 'standalone'
        end
    else
        FW.name = Config.Framework
    end

    if FW.name == 'esx' then
        FW.object = exports['es_extended']:getSharedObject()
    elseif FW.name == 'qbcore' then
        FW.object = exports['qb-core']:GetCoreObject()
    elseif FW.name == 'qbox' then
        FW.object = exports.qbx_core
    end

    print(('[jp-b2b_documents] Framework: %s'):format(FW.name))
end)

function FW.Notify(src, msg, nType)
    nType = nType or 'inform'
    if GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', src, {
            title = (nType == 'success' and T('success')) or (nType == 'error' and T('error')) or nil,
            description = msg,
            type = nType,
        })
        return
    end
    if FW.name == 'esx' and FW.object then
        TriggerClientEvent('esx:showNotification', src, msg)
    elseif FW.name == 'qbcore' and FW.object then
        TriggerClientEvent('QBCore:Notify', src, msg, nType)
    else
        TriggerClientEvent('chat:addMessage', src, { args = { '[jp-b2b_documents]', msg } })
    end
end

function FW.GetPlayer(src)
    if FW.name == 'esx' and FW.object then
        return FW.object.GetPlayerFromId(src)
    elseif FW.name == 'qbcore' and FW.object then
        return FW.object.Functions.GetPlayer(src)
    elseif FW.name == 'qbox' then
        return exports.qbx_core:GetPlayer(src)
    end
    return nil
end

function FW.RegisterUsableItem(itemName, cb)
    if FW.name == 'esx' and FW.object then
        FW.object.RegisterUsableItem(itemName, function(source)
            cb(source, { name = itemName })
        end)
    elseif FW.name == 'qbcore' and FW.object then
        FW.object.Functions.CreateUseableItem(itemName, function(source, item)
            cb(source, item or { name = itemName })
        end)
    elseif FW.name == 'qbox' then
        local ok = pcall(function()
            exports.qbx_core:CreateUseableItem(itemName, function(source, item)
                cb(source, item or { name = itemName })
            end)
        end)
        if not ok then
            print(('[jp-b2b_documents] CreateUseableItem 失敗: %s（qbx_core の API を確認してください）'):format(itemName))
        end
    end
end

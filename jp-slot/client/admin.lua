-- 管理 NUI → サーバー中継（RegisterNUICallback はクライアントのみ）

local pendingLoginCb = nil
local pendingChangePwCb = nil
local pendingPresetListByCharacterCb = nil
local pendingPresetGetCb = nil
local pendingPresetSaveNewCb = nil
local pendingPresetSaveOverwriteCb = nil
local pendingPresetDeleteCb = nil
local pendingPresetActiveCb = nil
local pendingAssetsScanCb = nil
local pendingCharactersListCb = nil

local function resName()
    return GetCurrentResourceName()
end

RegisterNUICallback('admin/login', function(data, cb)
    pendingLoginCb = cb
    TriggerServerEvent('jp-slot:sv:adminLogin', type(data) == 'table' and data or {})
end)

RegisterNetEvent('jp-slot:cl:adminLoginResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingLoginCb then
        pendingLoginCb(res)
        pendingLoginCb = nil
    end
    SendNUIMessage({ type = 'adminLoginResult', payload = res })
end)

RegisterNUICallback('admin/logout', function(data, cb)
    cb({ ok = true })
    data = type(data) == 'table' and data or {}
    TriggerServerEvent('jp-slot:sv:adminLogout', data)
end)

RegisterNUICallback('admin/changePassword', function(data, cb)
    pendingChangePwCb = cb
    TriggerServerEvent('jp-slot:sv:adminChangePw', type(data) == 'table' and data or {})
end)

RegisterNetEvent('jp-slot:cl:adminChangePwResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingChangePwCb then
        pendingChangePwCb(res)
        pendingChangePwCb = nil
    end
end)

RegisterNUICallback('admin/close', function(data, cb)
    cb({ ok = true })
    -- client/main.lua の finalize と同一（nuiOpen リセット・adminClosed 送信）
    TriggerEvent('__jp-slot:finalizeAdminClose')
end)

RegisterNUICallback('adminSaveTheme', function(body, cb)
    cb({ ok = true })
    body = type(body) == 'table' and body or {}
    TriggerServerEvent('jp-slot:sv:adminSaveTheme', {
        theme = body.theme,
        token = body.token,
    })
end)

RegisterNUICallback('admin/setUISize', function(data, cb)
    cb({ ok = true })
    data = type(data) == 'table' and data or {}
    TriggerServerEvent('jp-slot:sv:adminSetUISize', data)
end)

RegisterNUICallback('admin/resetUISize', function(data, cb)
    cb({ ok = true })
    data = type(data) == 'table' and data or {}
    TriggerServerEvent('jp-slot:sv:adminResetUISize', data)
end)

RegisterNUICallback('admin/preset/listByCharacter', function(data, cb)
    pendingPresetListByCharacterCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetListByCharacter', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/get', function(data, cb)
    pendingPresetGetCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetGet', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/saveNew', function(data, cb)
    pendingPresetSaveNewCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetSaveNew', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/saveOverwrite', function(data, cb)
    pendingPresetSaveOverwriteCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetSaveOverwrite', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/delete', function(data, cb)
    pendingPresetDeleteCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetDelete', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/setActive', function(data, cb)
    pendingPresetActiveCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetSetActive', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/assets/scan', function(data, cb)
    pendingAssetsScanCb = cb
    TriggerServerEvent('jp-slot:sv:adminAssetsScan', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/characters/list', function(data, cb)
    pendingCharactersListCb = cb
    TriggerServerEvent('jp-slot:sv:adminCharactersList', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/previewStart', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('jp-slot:sv:adminPreviewStart', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/previewEnd', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('jp-slot:sv:adminPreviewEnd', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/embedSlotInit', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('jp-slot:sv:adminEmbedSlotInit', type(data) == 'table' and data or {})
end)

RegisterNetEvent('jp-slot:cl:adminPresetListByCharacterResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetListByCharacterCb then
        pendingPresetListByCharacterCb(res)
        pendingPresetListByCharacterCb = nil
    end
end)

RegisterNetEvent('jp-slot:cl:adminPresetGetResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetGetCb then
        pendingPresetGetCb(res)
        pendingPresetGetCb = nil
    end
end)

RegisterNetEvent('jp-slot:cl:adminPresetSaveNewResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetSaveNewCb then
        pendingPresetSaveNewCb(res)
        pendingPresetSaveNewCb = nil
    end
end)

RegisterNetEvent('jp-slot:cl:adminPresetSaveOverwriteResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetSaveOverwriteCb then
        pendingPresetSaveOverwriteCb(res)
        pendingPresetSaveOverwriteCb = nil
    end
end)

RegisterNetEvent('jp-slot:cl:adminPresetDeleteResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetDeleteCb then
        pendingPresetDeleteCb(res)
        pendingPresetDeleteCb = nil
    end
end)

RegisterNetEvent('jp-slot:cl:adminPresetActiveResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetActiveCb then
        pendingPresetActiveCb(res)
        pendingPresetActiveCb = nil
    end
end)

RegisterNetEvent('jp-slot:cl:adminAssetsScanResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingAssetsScanCb then
        pendingAssetsScanCb(res)
        pendingAssetsScanCb = nil
    end
    SendNUIMessage({ type = 'adminAssetsScanResult', payload = res })
end)

RegisterNetEvent('jp-slot:cl:adminCharactersListResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingCharactersListCb then
        pendingCharactersListCb(res)
        pendingCharactersListCb = nil
    end
end)

RegisterNetEvent('jp-slot:adminDenied', function(payload)
    payload = type(payload) == 'table' and payload or {}
    print('[jp-slot] admin denied: ' .. tostring(payload.reason or 'unknown'))
end)

RegisterNetEvent('jp-slot:previewMode', function(p)
    SendNUIMessage({
        type = 'previewMode',
        payload = type(p) == 'table' and p or {},
    })
end)

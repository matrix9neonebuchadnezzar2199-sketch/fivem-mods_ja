-- 管理 NUI → サーバー中継（RegisterNUICallback はクライアントのみ）

local pendingLoginCb = nil
local pendingChangePwCb = nil
local pendingPresetListCb = nil
local pendingPresetGetCb = nil
local pendingPresetSaveCb = nil
local pendingPresetDeleteCb = nil
local pendingPresetActiveCb = nil
local pendingAssetsScanCb = nil

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
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = 'closeAdmin' })
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

RegisterNUICallback('admin/preset/list', function(data, cb)
    pendingPresetListCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetList', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/get', function(data, cb)
    pendingPresetGetCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetGet', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/preset/save', function(data, cb)
    pendingPresetSaveCb = cb
    TriggerServerEvent('jp-slot:sv:adminPresetSave', type(data) == 'table' and data or {})
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

RegisterNUICallback('admin/previewStart', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('jp-slot:sv:adminPreviewStart', type(data) == 'table' and data or {})
end)

RegisterNUICallback('admin/previewEnd', function(data, cb)
    cb({ ok = true })
    TriggerServerEvent('jp-slot:sv:adminPreviewEnd', type(data) == 'table' and data or {})
end)

RegisterNetEvent('jp-slot:cl:adminPresetListResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetListCb then
        pendingPresetListCb(res)
        pendingPresetListCb = nil
    end
    SendNUIMessage({ type = 'adminPresetListResult', payload = res })
end)

RegisterNetEvent('jp-slot:cl:adminPresetGetResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetGetCb then
        pendingPresetGetCb(res)
        pendingPresetGetCb = nil
    end
    SendNUIMessage({ type = 'adminPresetGetResult', payload = res })
end)

RegisterNetEvent('jp-slot:cl:adminPresetSaveResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetSaveCb then
        pendingPresetSaveCb(res)
        pendingPresetSaveCb = nil
    end
    SendNUIMessage({ type = 'adminPresetSaveResult', payload = res })
end)

RegisterNetEvent('jp-slot:cl:adminPresetDeleteResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetDeleteCb then
        pendingPresetDeleteCb(res)
        pendingPresetDeleteCb = nil
    end
    SendNUIMessage({ type = 'adminPresetDeleteResult', payload = res })
end)

RegisterNetEvent('jp-slot:cl:adminPresetActiveResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingPresetActiveCb then
        pendingPresetActiveCb(res)
        pendingPresetActiveCb = nil
    end
    SendNUIMessage({ type = 'adminPresetActiveResult', payload = res })
end)

RegisterNetEvent('jp-slot:cl:adminAssetsScanResult', function(res)
    res = type(res) == 'table' and res or {}
    if pendingAssetsScanCb then
        pendingAssetsScanCb(res)
        pendingAssetsScanCb = nil
    end
    SendNUIMessage({ type = 'adminAssetsScanResult', payload = res })
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

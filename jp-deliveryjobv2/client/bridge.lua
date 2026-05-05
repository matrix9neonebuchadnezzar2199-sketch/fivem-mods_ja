-- フレームワーク互換ブリッジ（クライアント側 / 日本語版）
-- ESX / QBCore の差分を吸収するためのラッパー

Bridge = {}
local ESX = nil
local QBCore = nil

-- フレームワーク自動検出
if Config['Framework'] == 'auto' then
    if GetResourceState('es_extended') == 'started' then
        Config['Framework'] = 'esx'
    elseif GetResourceState('qb-core') == 'started' then
        Config['Framework'] = 'qb'
    end
end

-- 検出されたフレームワークの参照を取得
if Config['Framework'] == 'esx' then
    ESX = exports['es_extended']:getSharedObject()
elseif Config['Framework'] == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- 通知表示（フレームワーク標準の通知システムを使用）
function Bridge.ShowNotification(msg, type)
    if Config['Framework'] == 'esx' then
        ESX.ShowNotification(msg, type)
    elseif Config['Framework'] == 'qb' then
        QBCore.Functions.Notify(msg, type)
    end
end

-- プレイヤーデータ取得
function Bridge.GetPlayerData()
    if Config['Framework'] == 'esx' then
        return ESX.GetPlayerData()
    elseif Config['Framework'] == 'qb' then
        return QBCore.Functions.GetPlayerData()
    end
end

-- 最寄りの車両を取得
function Bridge.GetClosestVehicle(coords)
    if Config['Framework'] == 'esx' then
        return ESX.Game.GetClosestVehicle(coords)
    elseif Config['Framework'] == 'qb' then
        return QBCore.Functions.GetClosestVehicle(coords)
    end
end

-- サーバーコールバック呼び出し
function Bridge.TriggerCallback(name, cb, ...)
    lib.callback(name, false, cb, ...)
end

-- プレイヤーが準備できるまで待機
CreateThread(function()
    while not ESX and not QBCore do
        Wait(100)
        if Config['Framework'] == 'esx' then
            ESX = exports['es_extended']:getSharedObject()
        elseif Config['Framework'] == 'qb' then
            QBCore = exports['qb-core']:GetCoreObject()
        end
    end
end)

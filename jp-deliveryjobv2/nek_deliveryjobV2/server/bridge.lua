-- フレームワーク互換ブリッジ（サーバー側 / 日本語版）

Bridge = {}
local ESX = nil
local QBCore = nil

-- フレームワーク自動検出
if Config['Framework'] == 'auto' then
    if GetResourceState('es_extended') == 'started' then
        Config['Framework'] = 'esx'
        print('nek_delivery: ESXフレームワークを使用します')
    elseif GetResourceState('qb-core') == 'started' then
        Config['Framework'] = 'qb'
        print('nek_delivery: QBCoreフレームワークを使用します')
    end
end

-- フレームワークオブジェクト取得
if Config['Framework'] == 'esx' then
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    if not ESX then ESX = exports['es_extended']:getSharedObject() end
elseif Config['Framework'] == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
end

-- プレイヤーオブジェクトを統一インターフェースで取得
function Bridge.GetPlayer(source)
    local self = {}
    self.source = source

    self.getIdentifiers = function()
        local discordId = GetPlayerIdentifierByType(source, 'discord')
        local licenseId = GetPlayerIdentifierByType(source, 'license')
        return {
            discord = discordId or 'discord:0',
            license = licenseId or 'N/A',
            ip = GetPlayerEndpoint(source) or '0.0.0.0'
        }
    end

    if Config['Framework'] == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return nil end

        self.original = xPlayer
        self.identifier = xPlayer.identifier
        self.getName = function() return xPlayer.getName() end
        self.addMoney = function(amount) xPlayer.addMoney(amount) end
    elseif Config['Framework'] == 'qb' then
        local xPlayer = QBCore.Functions.GetPlayer(source)
        if not xPlayer then return nil end

        self.original = xPlayer
        self.identifier = xPlayer.PlayerData.citizenid
        self.getName = function()
            return xPlayer.PlayerData.charinfo.firstname ..
                ' ' .. xPlayer.PlayerData.charinfo.lastname
        end
        self.addMoney = function(amount) xPlayer.Functions.AddMoney('cash', amount) end
    end

    return self
end

-- プレイヤーへの通知送信
function Bridge.Notify(source, msg, type)
    if Config['Framework'] == 'esx' then
        TriggerClientEvent('esx:showNotification', source, msg)
    elseif Config['Framework'] == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, msg, type)
    end
end

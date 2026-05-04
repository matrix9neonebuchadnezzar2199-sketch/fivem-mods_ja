-- bridge/framework.lua
-- フレームワーク差分吸収レイヤ（ESX / QBCore / Qbox / standalone）
-- クライアント側で動作する想定。

Bridge = {
    name = 'standalone',
    ready = false,
    onReadyCallbacks = {},
}

local function dprint(...)
    if Config and Config.Debug then print('[jp-mch:bridge]', ...) end
end

local function callReady()
    Bridge.ready = true
    for _, cb in ipairs(Bridge.onReadyCallbacks) do
        local ok, err = pcall(cb)
        if not ok then print('[jp-mch] onReady error: ' .. tostring(err)) end
    end
end

function Bridge.OnReady(cb)
    if Bridge.ready then
        cb()
    else
        table.insert(Bridge.onReadyCallbacks, cb)
    end
end

-- ============================================================
-- 検出
-- ============================================================
local function detect()
    local pref = (Config and Config.Framework) or 'auto'

    local function has(res)
        local st = GetResourceState(res)
        return st == 'started' or st == 'starting'
    end

    if pref == 'qbox' or (pref == 'auto' and has('qbx_core')) then
        return 'qbox'
    elseif pref == 'qb' or (pref == 'auto' and has('qb-core')) then
        return 'qb'
    elseif pref == 'esx' or (pref == 'auto' and (has('es_extended') or has('esx_legacy'))) then
        return 'esx'
    end
    return 'standalone'
end

-- ============================================================
-- 共通ユーティリティ
-- ============================================================
-- ESX 形式の accounts から (cash, bank, black) を抜き出す
local function extractEsxAccounts(accounts)
    local cash, bank, black = 0, 0, 0
    if not accounts then return cash, bank, black end
    local function v(a)
        return a.money or a.count or a.value or 0
    end
    for k, a in pairs(accounts) do
        local n = a.name or k
        if n == 'money' or n == 'cash' then
            cash = v(a)
        elseif n == 'bank' then
            bank = v(a)
        elseif n == 'black_money' or n == 'dirtycash' or n == 'illicit' then
            black = v(a)
        end
    end
    return cash, bank, black
end

-- ============================================================
-- ESX 実装
-- ============================================================
local function setupESX()
    local ESX
    local tries = 0
    while ESX == nil and tries < 200 do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        if ESX == nil then
            local ok, res = pcall(function()
                return exports['es_extended']:getSharedObject()
            end)
            if ok then ESX = res end
        end
        if ESX == nil and _G.ESX then ESX = _G.ESX end
        if ESX == nil then
            Wait(100)
            tries = tries + 1
        end
    end
    if not ESX then return false end

    function Bridge.GetMoney()
        local d = ESX.GetPlayerData and ESX.GetPlayerData() or {}
        return extractEsxAccounts(d.accounts)
    end

    function Bridge.GetJob()
        local d = ESX.GetPlayerData and ESX.GetPlayerData() or {}
        local j = d.job
        if not j then return nil end
        return {
            name = j.name,
            label = j.label or j.name,
            grade = j.grade or 0,
            grade_label = j.grade_label or (Locale.ui.grade_prefix .. ' ' .. tostring(j.grade or 0)),
        }
    end

    function Bridge.RegisterUpdates(onMoney, onJob)
        AddEventHandler('esx:setAccountMoney', function()
            local c, b, k = Bridge.GetMoney()
            onMoney(c, b, k)
        end)
        AddEventHandler('esx:setJob', function(job)
            onJob({
                name = job.name,
                label = job.label or job.name,
                grade = job.grade or 0,
                grade_label = job.grade_label or '',
            })
        end)
        AddEventHandler('esx:playerLoaded', function()
            Wait(200)
            local c, b, k = Bridge.GetMoney()
            onMoney(c, b, k)
            onJob(Bridge.GetJob())
        end)
    end

    return true
end

-- ============================================================
-- QBCore 実装
-- ============================================================
local function setupQB()
    local QBCore
    local ok, res = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)
    if ok then QBCore = res end
    if not QBCore then return false end

    local function getPD()
        return QBCore.Functions.GetPlayerData()
    end

    function Bridge.GetMoney()
        local d = getPD()
        local m = d and d.money or {}
        return tonumber(m.cash) or 0, tonumber(m.bank) or 0, tonumber(m['black_money']) or 0
    end

    function Bridge.GetJob()
        local d = getPD()
        local j = d and d.job
        if not j then return nil end
        return {
            name = j.name,
            label = j.label or j.name,
            grade = (j.grade and (j.grade.level or j.grade)) or 0,
            grade_label = (j.grade and j.grade.name)
                or (Locale.ui.grade_prefix .. ' ' .. tostring((j.grade and j.grade.level) or 0)),
        }
    end

    function Bridge.RegisterUpdates(onMoney, onJob)
        RegisterNetEvent('QBCore:Player:SetPlayerData', function(pd)
            if pd and pd.money then
                onMoney(
                    tonumber(pd.money.cash) or 0,
                    tonumber(pd.money.bank) or 0,
                    tonumber(pd.money['black_money']) or 0
                )
            end
            if pd and pd.job then onJob(Bridge.GetJob()) end
        end)
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
            Wait(200)
            local c, b, k = Bridge.GetMoney()
            onMoney(c, b, k)
            onJob(Bridge.GetJob())
        end)
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
            onJob(Bridge.GetJob())
        end)
        RegisterNetEvent('QBCore:Client:OnMoneyChange', function()
            local c, b, k = Bridge.GetMoney()
            onMoney(c, b, k)
        end)
    end

    return true
end

-- ============================================================
-- Qbox 実装（qbx_core）
-- ============================================================
local function setupQBox()
    local function pd()
        local ok, d = pcall(function()
            return exports.qbx_core:GetPlayerData()
        end)
        if ok then return d end
        return nil
    end

    function Bridge.GetMoney()
        local d = pd()
        local m = d and d.money or {}
        return tonumber(m.cash) or 0, tonumber(m.bank) or 0, tonumber(m['black_money']) or 0
    end

    function Bridge.GetJob()
        local d = pd()
        local j = d and d.job
        if not j then return nil end
        return {
            name = j.name,
            label = j.label or j.name,
            grade = (j.grade and (j.grade.level or j.grade)) or 0,
            grade_label = (j.grade and j.grade.name)
                or (Locale.ui.grade_prefix .. ' ' .. tostring((j.grade and j.grade.level) or 0)),
        }
    end

    function Bridge.RegisterUpdates(onMoney, onJob)
        RegisterNetEvent('QBCore:Player:SetPlayerData', function(p)
            if p and p.money then
                onMoney(
                    tonumber(p.money.cash) or 0,
                    tonumber(p.money.bank) or 0,
                    tonumber(p.money['black_money']) or 0
                )
            end
            if p and p.job then onJob(Bridge.GetJob()) end
        end)
        RegisterNetEvent('qbx_core:client:onPlayerLoaded', function()
            Wait(200)
            local c, b, k = Bridge.GetMoney()
            onMoney(c, b, k)
            onJob(Bridge.GetJob())
        end)
        RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
            onJob(Bridge.GetJob())
        end)
        RegisterNetEvent('QBCore:Client:OnMoneyChange', function()
            local c, b, k = Bridge.GetMoney()
            onMoney(c, b, k)
        end)
    end

    return true
end

-- ============================================================
-- standalone 実装：イベント駆動だけ
-- ============================================================
local function setupStandalone()
    local cash, bank, black = 0, 0, 0
    local job = nil

    function Bridge.GetMoney()
        return cash, bank, black
    end

    function Bridge.GetJob()
        return job
    end

    function Bridge.RegisterUpdates(onMoney, onJob)
        local function setMoney(c, b, k)
            cash, bank, black = tonumber(c) or 0, tonumber(b) or 0, tonumber(k) or 0
            onMoney(cash, bank, black)
            if Config and Config.Debug and Locale and Locale.log then
                print(string.format(Locale.log.bridge_money_evt, tostring(cash), tostring(bank), tostring(black)))
            end
        end

        local function setJob(j)
            job = j
            onJob(j)
        end

        RegisterNetEvent('jp-mch:setMoney')
        AddEventHandler('jp-mch:setMoney', setMoney)
        RegisterNetEvent('jp-mch:setJob')
        AddEventHandler('jp-mch:setJob', setJob)

        RegisterNetEvent('hud:updateMoney')
        AddEventHandler('hud:updateMoney', setMoney)
        RegisterNetEvent('hud:updateJob')
        AddEventHandler('hud:updateJob', setJob)
    end

    return true
end

-- ============================================================
-- 初期化
-- ============================================================
CreateThread(function()
    Wait(200)
    local kind = detect()
    Bridge.name = kind

    local ok = false
    if kind == 'qbox' then
        ok = setupQBox()
    elseif kind == 'qb' then
        ok = setupQB()
    elseif kind == 'esx' then
        ok = setupESX()
    end
    if not ok then
        Bridge.name = 'standalone'
        setupStandalone()
        print((Locale and Locale.log and Locale.log.fw_not_found) or '[jp-mch] standalone')
    else
        print(string.format((Locale and Locale.log and Locale.log.fw_detected) or '[jp-mch] FW=%s', Bridge.name))
    end

    callReady()
end)

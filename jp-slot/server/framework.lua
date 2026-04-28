-- ESX / QBCore / standalone を同一インターフェースで切替（上位は account を渡すだけ）
Framework = {}

local ESX = nil
local QBCore = nil
local impl = nil
local modeLabel = 'standalone'

--- 検出結果のラベル（ログ用）
---@return string
function Framework.getMode()
    ensureImpl()
    return modeLabel
end

--- プライマリ識別子（standalone の KVP キーに使用。サーバー ID ではなく license 等）
---@param source number
---@return string|nil
function Framework.getPrimaryIdentifier(source)
    local ids = GetPlayerIdentifiers(source)
    if not ids then
        return nil
    end
    for i = 1, #ids do
        local id = ids[i]
        if id and string.sub(id, 1, 8) == 'license:' then
            return id
        end
    end
    return ids[1]
end

---@param account string|nil
---@return string
local function resolveAccount(account)
    local a = account
    if not a or a == '' then
        a = Config.MoneyAccount or 'cash'
    end
    return a
end

--- 仮想ウォレット KVP（jp-slot:wallet:{identifier}）
---@param identifier string|nil
---@return string|nil
local function walletKey(identifier)
    if not identifier or identifier == '' then
        return nil
    end
    return 'jp-slot:wallet:' .. identifier
end

--- 旧キー（移行用）
---@param identifier string|nil
---@return string|nil
local function legacyBalanceKey(identifier)
    if not identifier or identifier == '' then
        return nil
    end
    return 'jp-slot:balance:' .. identifier
end

---@param identifier string|nil
---@return number
local function getStandaloneBalance(identifier)
    local key = walletKey(identifier)
    if not key then
        return 0
    end
    local raw = GetResourceKvpString(key)
    if raw and raw ~= '' then
        local n = tonumber(raw)
        return n and (n + 0.0) or (Config.DebugSettings.InitialBalance + 0.0)
    end
    local leg = GetResourceKvpString(legacyBalanceKey(identifier) or '')
    if leg and leg ~= '' then
        SetResourceKvp(key, leg)
        local n = tonumber(leg)
        return n and (n + 0.0) or (Config.DebugSettings.InitialBalance + 0.0)
    end
    return Config.DebugSettings.InitialBalance + 0.0
end

---@param identifier string|nil
---@param amount number
local function setStandaloneBalance(identifier, amount)
    local key = walletKey(identifier)
    if not key then
        return
    end
    SetResourceKvp(key, tostring(math.floor(amount + 0.5)))
end

--- standalone 実装
---@return table
local function require_standalone()
    return {
        getMoney = function(source, account)
            local ident = Framework.getPrimaryIdentifier(source)
            return getStandaloneBalance(ident)
        end,
        removeMoney = function(source, account, amount)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then
                return true
            end
            local ident = Framework.getPrimaryIdentifier(source)
            local bal = getStandaloneBalance(ident)
            if bal < amount then
                return false
            end
            setStandaloneBalance(ident, bal - amount)
            return true
        end,
        addMoney = function(source, account, amount)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then
                return
            end
            local ident = Framework.getPrimaryIdentifier(source)
            local bal = getStandaloneBalance(ident)
            setStandaloneBalance(ident, bal + amount)
        end,
    }
end

--- ESX 実装
---@return table|nil
local function require_esx()
    if not ESX then
        return nil
    end
    return {
        getMoney = function(source, account)
            local acc = resolveAccount(account)
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then
                return 0
            end
            if acc == 'bank' and xPlayer.getAccount then
                local b = xPlayer.getAccount('bank')
                return b and b.money or 0
            end
            return xPlayer.getMoney and xPlayer.getMoney() or 0
        end,
        removeMoney = function(source, account, amount)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then
                return true
            end
            local acc = resolveAccount(account)
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then
                return false
            end
            if acc == 'bank' and xPlayer.getAccount then
                local bank = xPlayer.getAccount('bank')
                if bank and bank.money >= amount and xPlayer.removeAccountMoney then
                    xPlayer.removeAccountMoney('bank', amount)
                    return true
                end
                return false
            end
            if xPlayer.getMoney and xPlayer.getMoney() >= amount and xPlayer.removeMoney then
                xPlayer.removeMoney(amount)
                return true
            end
            return false
        end,
        addMoney = function(source, account, amount)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then
                return
            end
            local acc = resolveAccount(account)
            local xPlayer = ESX.GetPlayerFromId(source)
            if not xPlayer then
                return
            end
            if acc == 'bank' and xPlayer.addAccountMoney then
                xPlayer.addAccountMoney('bank', amount)
                return
            end
            if xPlayer.addMoney then
                xPlayer.addMoney(amount)
            end
        end,
    }
end

--- QBCore 実装
---@return table|nil
local function require_qbcore()
    if not QBCore then
        return nil
    end
    return {
        getMoney = function(source, account)
            local acc = resolveAccount(account)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player or not Player.PlayerData or not Player.PlayerData.money then
                return 0
            end
            local key = acc == 'bank' and 'bank' or 'cash'
            local v = Player.PlayerData.money[key]
            return tonumber(v) or 0
        end,
        removeMoney = function(source, account, amount)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then
                return true
            end
            local acc = resolveAccount(account)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then
                return false
            end
            local qacc = acc == 'bank' and 'bank' or 'cash'
            local r = Player.Functions.RemoveMoney(qacc, amount, 'jp-slot-spin')
            return r ~= false
        end,
        addMoney = function(source, account, amount)
            amount = math.floor(tonumber(amount) or 0)
            if amount <= 0 then
                return
            end
            local acc = resolveAccount(account)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then
                return
            end
            local qacc = acc == 'bank' and 'bank' or 'cash'
            Player.Functions.AddMoney(qacc, amount, 'jp-slot-payout')
        end,
    }
end

local function tryEsx()
    if pcall(function()
        ESX = exports['es_extended']:getSharedObject()
    end) and ESX then
        impl = require_esx()
        modeLabel = 'esx'
        print('[jp-slot] Framework detected: ESX')
        return true
    end
    return false
end

local function tryQb()
    if pcall(function()
        QBCore = exports['qb-core']:GetCoreObject()
    end) and QBCore then
        impl = require_qbcore()
        modeLabel = 'qbcore'
        print('[jp-slot] Framework detected: QBCore')
        return true
    end
    return false
end

--- 内部 impl を確定（初回呼び出し時）
local function ensureImpl()
    if impl then
        return
    end
    local want = Config.Framework or 'auto'
    if want == 'auto' then
        if GetResourceState('es_extended') == 'started' then
            tryEsx()
        elseif GetResourceState('qb-core') == 'started' then
            tryQb()
        end
        if not impl then
            if not tryEsx() then
                tryQb()
            end
        end
    elseif want == 'esx' or want == 'es_extended' then
        tryEsx()
    elseif want == 'qb' or want == 'qbcore' then
        tryQb()
    end
    if not impl then
        impl = require_standalone()
        modeLabel = 'standalone'
        print('[jp-slot] Framework detected: Standalone (KVS仮想残高モード)')
    end
end

---@param source number
---@param account string|nil 'cash'|'bank' など（省略時は Config.MoneyAccount）
---@return number
function Framework.getMoney(source, account)
    ensureImpl()
    return impl.getMoney(source, account)
end

---@param source number
---@param account string|nil
---@param amount number
---@return boolean
function Framework.removeMoney(source, account, amount)
    ensureImpl()
    return impl.removeMoney(source, account, amount)
end

---@param source number
---@param account string|nil
---@param amount number
function Framework.addMoney(source, account, amount)
    ensureImpl()
    impl.addMoney(source, account, amount)
end

CreateThread(function()
    Wait(100)
    ensureImpl()
end)

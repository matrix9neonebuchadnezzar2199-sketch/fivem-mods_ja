-- フレームワーク: auto 時は qbx / ESX / QBCore / ox(現金アイテム) の優先で検出
local ESX, QBCore = nil, nil
--- 'none' 'esx' 'qb' 'qbx' 'oxinv'（ox_core の口座は未対応のため ox_inv の money のみで代替）
local MoneyMode = 'none'
--- KVS 永続化: 管理画面の設定（タイトル・価格・%・アイテムごと）
local GachaKvs = {
    version = 1,
    title = nil,
    cost = nil,
    theme = 'neon',
    rarityPct = { UR = 10, SSR = 4, SR = 10, R = 76 },
    itemSettings = {}
}

local function InitFramework()
    if Config.Framework == 'esx' or Config.Framework == 'es_extended' then
        if pcall(function() ESX = exports['es_extended']:getSharedObject() end) and ESX then
            MoneyMode = 'esx'
        end
        return
    end
    if Config.Framework == 'qb' or Config.Framework == 'qbcore' then
        if pcall(function() QBCore = exports['qb-core']:GetCoreObject() end) and QBCore then
            MoneyMode = 'qb'
        end
        return
    end
    if Config.Framework == 'qbox' or Config.Framework == 'qbx' then
        if GetResourceState('qbx_core') == 'started' then
            MoneyMode = 'qbx'
        end
        return
    end
    if Config.Framework == 'oxinv' or Config.Framework == 'ox_inventory' then
        if GetResourceState('ox_inventory') == 'started' then
            MoneyMode = 'oxinv'
        end
        return
    end
    if GetResourceState('qbx_core') == 'started' then
        MoneyMode = 'qbx'
        if Config.Debug then
            print('[jp-gacha] 自動: qbx_core (Qbox)')
        end
        return
    end
    if pcall(function() ESX = exports['es_extended']:getSharedObject() end) and ESX then
        MoneyMode = 'esx'
        if Config.Debug then print('[jp-gacha] 自動: es_extended') end
        return
    end
    if pcall(function() QBCore = exports['qb-core']:GetCoreObject() end) and QBCore then
        MoneyMode = 'qb'
        if Config.Debug then print('[jp-gacha] 自動: qb-core') end
        return
    end
    if GetResourceState('ox_inventory') == 'started' then
        MoneyMode = 'oxinv'
        if Config.Debug then
            print('[jp-gacha] 自動: ox_inventory（money 現金）')
        end
        return
    end
    if Config.Debug then
        print('[jp-gacha] 自動: 金検出なし（無料で回せるモード。Framework を設定するか esx/qb/ox 系を導入してください）')
    end
end

Citizen.CreateThread(function()
    Wait(300)
    InitFramework()
end)

-- KVS: このリソースの KVP
local KVP_KEY = 'jp_gacha_settings_v1'
local KVP_ADMIN_PW = 'jp_gacha_admin_password'
-- 管理画面: パスワード or /gachaadmin(ACE) で解除後に true
local AdminUnlocked = {}

local function NewDefaultGachaKvs()
    return {
        version = 1,
        title = Config.MenuTitle,
        cost = Config.Cost,
        theme = 'neon',
        rarityPct = { UR = 10, SSR = 4, SR = 10, R = 76 },
        itemSettings = {}
    }
end

local function TableCopyShallow(t)
    local o = {}
    for k, v in pairs(t or {}) do
        o[k] = v
    end
    return o
end

---@return table|nil
local function GetRarityRowById(rarityId)
    for _, r in ipairs(Config.Rarities) do
        if r.id == rarityId then
            return r
        end
    end
    return nil
end

-- 4段階（R含む）用の可視行。N 相当は R 扱いで R 行を使う
local function MapFourTierToRowId(rollId)
    if rollId == 'R' or rollId == 'N' then
        return 'R'
    end
    if rollId == 'SR' or rollId == 'SSR' or rollId == 'UR' then
        return rollId
    end
    return 'R'
end

local function LoadGachaKvs()
    local raw
    if GetResourceKvpString then
        raw = GetResourceKvpString(KVP_KEY)
    else
        raw = GetResourceKvp and GetResourceKvp(KVP_KEY) or nil
    end
    local d = NewDefaultGachaKvs()
    if raw and raw ~= '' then
        local ok, decoded = pcall(function()
            return json.decode(raw)
        end)
        if ok and type(decoded) == 'table' then
            d.title = decoded.title or d.title
            d.cost = tonumber(decoded.cost) or d.cost
            d.theme = decoded.theme or d.theme
            if type(decoded.rarityPct) == 'table' then
                d.rarityPct.UR = tonumber(decoded.rarityPct.UR) or d.rarityPct.UR
                d.rarityPct.SSR = tonumber(decoded.rarityPct.SSR) or d.rarityPct.SSR
                d.rarityPct.SR = tonumber(decoded.rarityPct.SR) or d.rarityPct.SR
                d.rarityPct.R = tonumber(decoded.rarityPct.R) or d.rarityPct.R
            end
            if type(decoded.itemSettings) == 'table' then
                d.itemSettings = TableCopyShallow(decoded.itemSettings)
            end
        end
    end
    GachaKvs = d
end

local function SaveGachaKvs()
    local ok, err = pcall(function()
        local enc = json.encode(GachaKvs)
        if enc and SetResourceKvpString then
            SetResourceKvpString(KVP_KEY, enc)
        elseif enc then
            SetResourceKvp(KVP_KEY, enc)
        end
    end)
    if not ok and Config.Debug then
        print('[jp-gacha] KVP save fail: ' .. tostring(err))
    end
end

local function KvpGetStr(key)
    if GetResourceKvpString then
        return GetResourceKvpString(key) or nil
    end
    if GetResourceKvp then
        return GetResourceKvp(key) or nil
    end
    return nil
end

local function KvpSetStr(key, val)
    if SetResourceKvpString and val then
        SetResourceKvpString(key, val)
    elseif SetResourceKvp and val then
        SetResourceKvp(key, val)
    end
end

local function GetStoredAdminPassword()
    local p = KvpGetStr(KVP_ADMIN_PW)
    if not p or p == '' then
        return tostring(Config.AdminPassword or 'admin')
    end
    return p
end

local function SetStoredAdminPassword(plain)
    if type(plain) ~= 'string' or #plain < 1 then
        return false
    end
    KvpSetStr(KVP_ADMIN_PW, plain)
    return true
end

--- 初回のみ Config を KVS に焼き付け
local function EnsureAdminPasswordKvp()
    local p = KvpGetStr(KVP_ADMIN_PW)
    if not p or p == '' then
        SetStoredAdminPassword(tostring(Config.AdminPassword or 'admin'))
    end
end

-- ox: アイテム表示名
local function GetOxItemLabel(name)
    if not name or GetResourceState('ox_inventory') ~= 'started' then
        return name or ''
    end
    local ok, ret = pcall(function()
        local d = exports.ox_inventory:Items(name)
        if d and d.label then
            return d.label
        end
    end)
    if ok and ret and ret ~= '' then
        return ret
    end
    return name
end

---@return string
-- ガチャNUI(CEF) では nui:// 他リソースが効かない場合があるため cfx-nui- を採用
local function GetOxItemImageNui(name)
    if not name or GetResourceState('ox_inventory') ~= 'started' then
        return ''
    end
    return 'https://cfx-nui-ox_inventory/web/images/' .. tostring(name) .. '.png'
end

-- 景品候補カタログ: ox:item名（在庫0含む）。Config枠は CatalogStashOnly==false 時のみ
local function BuildPrizeCatalog()
    local out = {}
    if not (Config.CatalogStashOnly == true) and Config.ItemsByRarity then
        for _, rKey in ipairs({ 'N', 'R', 'SR', 'SSR', 'UR' }) do
            local arr = (Config.ItemsByRarity and Config.ItemsByRarity[rKey]) or {}
            for i, it in ipairs(arr) do
                out[#out + 1] = {
                    id = 'cfg:' .. rKey .. ':' .. i,
                    name = (it and it.name) or '?',
                    label = (it and it.name) or '?',
                    image = (it and it.image) or '',
                    isOx = false,
                    count = 99999,
                    cfgRarity = rKey
                }
            end
        end
    end
    if GetResourceState('ox_inventory') == 'started' and Config.StashName then
        local ok, inv = pcall(function()
            return exports.ox_inventory:GetInventory(Config.StashName, false)
        end)
        if ok and inv and inv.items then
            local oxByName = {}
            for _slot, v in pairs(inv.items) do
                if v and v.name then
                    local n = tostring(v.name)
                    if not oxByName[n] then
                        oxByName[n] = 0
                    end
                    oxByName[n] = oxByName[n] + (v.count or 0)
                end
            end
            for n, cnt in pairs(oxByName) do
                out[#out + 1] = {
                    id = 'ox:' .. n,
                    name = n,
                    label = GetOxItemLabel(n) or n,
                    image = GetOxItemImageNui(n),
                    isOx = true,
                    count = cnt,
                    cfgRarity = nil
                }
            end
        end
    end
    return out
end

local function DefaultSettingForEntry(entry)
    if entry.isOx then
        return { enabled = true, rarity = 'R' }
    end
    -- cfg: N 相当は 4 段階上は R に寄せる
    local c = entry.cfgRarity
    if c == 'N' or c == 'R' then
        return { enabled = true, rarity = 'R' }
    end
    if c == 'SR' then
        return { enabled = true, rarity = 'SR' }
    end
    if c == 'SSR' then
        return { enabled = true, rarity = 'SSR' }
    end
    if c == 'UR' then
        return { enabled = true, rarity = 'UR' }
    end
    return { enabled = true, rarity = 'R' }
end

local function GetItemSetting(id)
    local s = (GachaKvs.itemSettings and GachaKvs.itemSettings[id]) or nil
    if not s then
        return nil
    end
    return { enabled = s.enabled ~= false, rarity = s.rarity or 'R' }
end

-- 4段階レア中の有効アイテム数
local function CountEnabledInTier(tier, catalog, settingsUsed)
    local n = 0
    for _, e in ipairs(catalog) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        if settingsUsed then
            if not GachaKvs.itemSettings[e.id] and settingsUsed[e.id] then
                s = settingsUsed[e.id]
            end
        end
        if s.enabled and s.rarity == tier then
            if (not e.isOx) or ((e.count or 0) > 0) then
                n = n + 1
            end
        end
    end
    return n
end

-- 1 アイテム当たりの%（UI向け）: レア内均等
local function ComputeItemProbabilities(catalog, rarityPct)
    local rp = GachaKvs.rarityPct or { UR = 0, SSR = 0, SR = 0, R = 0 }
    if type(rarityPct) == 'table' then
        rp = TableCopyShallow(rarityPct)
    end
    local tiers = { 'UR', 'SSR', 'SR', 'R' }
    local nBy = {}
    for _, t in ipairs(tiers) do
        nBy[t] = CountEnabledInTier(t, catalog, nil)
    end
    local out = {}
    for _, e in ipairs(catalog) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        if not s.enabled or ((e.isOx) and (e.count or 0) <= 0) then
            out[e.id] = 0
        else
            local tier = s.rarity
            local pctR = (rp[tier] or 0) / 100.0
            local denom = nBy[tier] or 0
            if denom < 1 then
                out[e.id] = 0
            else
                out[e.id] = (pctR / denom) * 100.0
            end
        end
    end
    return out, nBy
end

-- 4段階レアの抽選（100% 前提）
local function DrawFourTierRarity()
    local p = GachaKvs.rarityPct
    if not p then
        p = { UR = 10, SSR = 4, SR = 10, R = 76 }
    end
    local total = (tonumber(p.UR) or 0) + (tonumber(p.SSR) or 0) + (tonumber(p.SR) or 0) + (tonumber(p.R) or 0)
    if total < 0.1 then
        return 'R'
    end
    local roll = math.random() * total
    local c = 0
    c = c + (tonumber(p.UR) or 0)
    if roll <= c then
        return 'UR'
    end
    c = c + (tonumber(p.SSR) or 0)
    if roll <= c then
        return 'SSR'
    end
    c = c + (tonumber(p.SR) or 0)
    if roll <= c then
        return 'SR'
    end
    return 'R'
end

-- 1 件の当選: rollId=UR/SSR/SR/R
local function DrawOnePrize(rollId, catalog)
    local pool = {}
    for _, e in ipairs(catalog) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        if s.rarity == rollId and s.enabled and ((not e.isOx) or ((e.count or 0) > 0)) then
            pool[#pool + 1] = e
        end
    end
    if #pool == 0 then
        for _attempt = 1, 5 do
            local alt = DrawFourTierRarity()
            local pool2 = {}
            for _, e in ipairs(catalog) do
                local s2 = GetItemSetting(e.id) or DefaultSettingForEntry(e)
                if s2.rarity == alt and s2.enabled and ((not e.isOx) or ((e.count or 0) > 0)) then
                    pool2[#pool2 + 1] = e
                end
            end
            if #pool2 > 0 then
                pool = pool2
                rollId = alt
                break
            end
        end
    end
    if #pool == 0 then
        for _, e in ipairs(catalog) do
            local s3 = GetItemSetting(e.id) or DefaultSettingForEntry(e)
            if s3.enabled and ((not e.isOx) or ((e.count or 0) > 0)) then
                local rid = s3.rarity
                if rid == 'UR' or rid == 'SSR' or rid == 'SR' or rid == 'R' then
                    return e, MapFourTierToRowId(rid)
                end
            end
        end
    end
    if #pool == 0 then
        return nil, 'R'
    end
    local pick = pool[math.random(#pool)]
    return pick, MapFourTierToRowId(rollId)
end

-- レガシー（Config の weight だけ使用）
local function TryChargeMoney(source, amount)
    if not amount or amount < 0 then
        return true
    end
    if amount == 0 then
        return true
    end
    if MoneyMode == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then
            return false
        end
        if xPlayer.getMoney and xPlayer.getMoney() >= amount and xPlayer.removeMoney then
            xPlayer.removeMoney(amount)
            return true
        end
        return false
    end
    if (MoneyMode == 'qb' and QBCore) or MoneyMode == 'qbx' then
        local Player
        if MoneyMode == 'qbx' then
            Player = exports.qbx_core:GetPlayer(source)
        else
            Player = QBCore.Functions.GetPlayer(source)
        end
        if not Player or not Player.PlayerData or not Player.PlayerData.money then
            return false
        end
        local cash = Player.PlayerData.money.cash
        if cash == nil then
            cash = 0
        end
        if type(cash) == 'string' then
            cash = tonumber(cash) or 0
        end
        if cash < amount then
            return false
        end
        if not Player.Functions or not Player.Functions.RemoveMoney then
            return false
        end
        local r = Player.Functions.RemoveMoney('cash', amount, 'jp-gacha')
        return r ~= false
    end
    if MoneyMode == 'oxinv' and GetResourceState('ox_inventory') == 'started' then
        local have = exports.ox_inventory:Search(source, 'count', 'money') or 0
        if have < amount then
            return false
        end
        if exports.ox_inventory:RemoveItem(source, 'money', amount) then
            return true
        end
        return false
    end
    return true
end

local function GetEffectiveCost()
    local c = GachaKvs and tonumber(GachaKvs.cost)
    if c and c >= 0 then
        return c
    end
    return tonumber(Config.Cost) or 0
end

--- スタッシュから1個抜き、プレイヤーに付与（ox_inventory 必須）
local function TransferOneFromStashToPlayer(playerSrc, itemName)
    if not itemName or GetResourceState('ox_inventory') ~= 'started' or not Config.StashName then
        return false
    end
    local sid = tostring(Config.StashName)
    local pOk, r1, r2 = pcall(function()
        return exports.ox_inventory:RemoveItem(sid, tostring(itemName), 1)
    end)
    if not pOk or not r1 then
        if Config.Debug then
            print(('[jp-gacha] スタッシュから取り出し失敗: %s (%s)'):format(
                tostring(itemName), tostring(r2)
            ))
        end
        return false
    end
    local aOk, a1, a2 = pcall(function()
        return exports.ox_inventory:AddItem(playerSrc, tostring(itemName), 1)
    end)
    if not aOk or not a1 then
        pcall(function()
            exports.ox_inventory:AddItem(sid, tostring(itemName), 1)
        end)
        if Config.Debug then
            print(('[jp-gacha] プレイヤー付与失敗: %s -> スタッシュへ戻し (%s)'):format(
                tostring(itemName), tostring(a2)
            ))
        end
        return false
    end
    return true
end

local function BuildDrawResult(pick, visualRarityId)
    local rrow = GetRarityRowById(visualRarityId) or GetRarityRowById('R') or Config.Rarities[1]
    local sp = (pick and pick.name) and tostring(pick.name) or ''
    local img = (pick and pick.image) and tostring(pick.image) or ''
    if sp ~= '' and img == '' and pick and pick.isOx and GetResourceState('ox_inventory') == 'started' then
        img = GetOxItemImageNui(sp)
    end
    return {
        rarityId = rrow.id,
        rarityName = rrow.name,
        rarityColor = rrow.color,
        capsule = rrow.capsule,
        bg = rrow.bg,
        cutin = rrow.cutin,
        itemName = (pick and pick.label) or (pick and pick.name) or '不明',
        itemImage = img,
        itemSpawnName = sp,
    }
end

local function DrawRarity()
    local totalWeight = 0
    for _, r in ipairs(Config.Rarities) do
        totalWeight = totalWeight + r.weight
    end
    local roll = math.random() * totalWeight
    local cumulative = 0
    for _, r in ipairs(Config.Rarities) do
        cumulative = cumulative + r.weight
        if roll <= cumulative then
            return r
        end
    end
    return Config.Rarities[1]
end

local function DrawItemFromConfig(rarityId)
    if type(Config.ItemsByRarity) == 'table' and type(Config.ItemsByRarity[rarityId]) == 'table' then
        local byRarityPool = Config.ItemsByRarity[rarityId]
        if #byRarityPool > 0 then
            local picked = byRarityPool[math.random(#byRarityPool)]
            return { name = picked.name or "不明", rarity = rarityId, image = picked.image or "" }
        end
    end
    local pool = {}
    for _, item in ipairs(Config.Items) do
        if item.rarity == rarityId then
            pool[#pool + 1] = item
        end
    end
    if #pool == 0 then
        return { name = "不明", rarity = rarityId, image = "" }
    end
    return pool[math.random(#pool)]
end

local function LegacyMultiDrawRow(rarity, item)
    return {
        index = 0, -- 後で付与
        rarityId = rarity.id,
        rarityName = rarity.name,
        rarityColor = rarity.color,
        capsule = rarity.capsule,
        bg = rarity.bg,
        cutin = rarity.cutin,
        itemName = item.name,
        itemImage = item.image or '',
        itemSpawnName = (item and item.name) and tostring(item.name) or '',
    }
end

local function HasAnyEnablePool()
    local c = BuildPrizeCatalog()
    for _, e in ipairs(c) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        if s.enabled and ((not e.isOx) or (e.count or 0) > 0) then
            if s.rarity == 'UR' or s.rarity == 'SSR' or s.rarity == 'SR' or s.rarity == 'R' then
                return true
            end
        end
    end
    return false
end

local function RegisterStashIfNeeded()
    if GetResourceState('ox_inventory') ~= 'started' or not Config.StashName then
        return
    end
    pcall(function()
        local sid = tostring(Config.StashName)
        local lab = tostring(Config.StashLabel or '景品')
        local slots = math.floor(tonumber(Config.StashSlots) or 100)
        local w = math.floor(tonumber(Config.StashMaxWeight) or 2000000)
        exports.ox_inventory:RegisterStash(sid, lab, slots, w, false)
    end)
end

Citizen.CreateThread(function()
    Wait(800)
    RegisterStashIfNeeded()
    EnsureAdminPasswordKvp()
    LoadGachaKvs()
end)

AddEventHandler('onResourceStart', function(name)
    if name == 'ox_inventory' or name == GetCurrentResourceName() then
        RegisterStashIfNeeded()
    end
end)

local PlayerCooldowns = {}

local function SendAdminDataToClient(src)
    LoadGachaKvs()
    local catalog = BuildPrizeCatalog()
    local outItems = {}
    for _, e in ipairs(catalog) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        outItems[#outItems + 1] = {
            id = e.id,
            name = e.name,
            label = e.label,
            count = e.isOx and (e.count or 0) or -1,
            enabled = s.enabled,
            rarity = s.rarity,
        }
    end
    TriggerClientEvent('jp-gacha:adminData', src, {
        settings = {
            title = GachaKvs.title or Config.MenuTitle,
            cost = GetEffectiveCost(),
            theme = GachaKvs.theme or 'neon',
            rarityPct = {
                UR = (GachaKvs.rarityPct and GachaKvs.rarityPct.UR) or 10,
                SSR = (GachaKvs.rarityPct and GachaKvs.rarityPct.SSR) or 4,
                SR = (GachaKvs.rarityPct and GachaKvs.rarityPct.SR) or 10,
                R = (GachaKvs.rarityPct and GachaKvs.rarityPct.R) or 76,
            },
        },
        items = outItems,
        rarities = Config.RarityDisplayNames
    })
end

local function BuildMenuItemRows()
    local catalog = BuildPrizeCatalog()
    local probs, _nBy = ComputeItemProbabilities(catalog, GachaKvs.rarityPct)
    local rows = {}
    for _, e in ipairs(catalog) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        if not s.enabled then
            -- 非表示
        else
            local c = e.isOx and (e.count or 0) or 999
            local outOf = e.isOx and c <= 0
            local prob = (outOf) and 0.0 or ((probs and probs[e.id]) or 0.0)
            if not outOf and e.isOx then
                -- ok
            elseif not e.isOx then
                outOf = false
            end
            rows[#rows + 1] = {
                id = e.id,
                name = e.name,
                label = e.label,
                count = e.isOx and (e.count or 0) or -1,
                image = e.image,
                enabled = s.enabled,
                rarity = s.rarity,
                outOfStock = outOf and true or false,
                prob = math.floor((prob * 100) + 0.5) / 100.0
            }
        end
    end
    return rows
end

---@return boolean, string? err
local function ValidateRarityTotal(pct)
    if type(pct) ~= 'table' then
        return false, 'rarity'
    end
    local t = (tonumber(pct.UR) or 0) + (tonumber(pct.SSR) or 0) + (tonumber(pct.SR) or 0) + (tonumber(pct.R) or 0)
    if t < 99.5 or t > 100.5 then
        return false, 'rarity'
    end
    return true
end

RegisterNetEvent('jp-gacha:requestGachaMenuData', function()
    local src = source
    LoadGachaKvs()
    local rows = BuildMenuItemRows()
    local title = GachaKvs.title or Config.MenuTitle
    local cost = GetEffectiveCost()
    local theme = GachaKvs.theme or 'neon'
    TriggerClientEvent('jp-gacha:gachaMenuData', src, {
        title = title,
        cost = cost,
        theme = theme,
        items = rows,
        themes = Config.Themes,
        rarities = Config.RarityDisplayNames,
        maxPull = Config.MaxPullCount,
        scale = Config.UIScale,
    })
end)

-- 緊急: ACE command.<gachaadmin> 必須。パスワード不要
RegisterNetEvent('jp-gacha:requestAdminData', function()
    local src = source
    local cmd = 'command.' .. tostring(Config.AdminCommand or 'gachaadmin')
    if not IsPlayerAceAllowed(src, cmd) then
        TriggerClientEvent('jp-gacha:adminCommandDenied', src)
        if Config.Debug then
            print(('[jp-gacha] /%s: ACE なし'):format(tostring(Config.AdminCommand)))
        end
        return
    end
    AdminUnlocked[src] = true
    SendAdminDataToClient(src)
end)

-- マシン: KVS パスワードと照合。purpose: 'admin' 管理UI / 'stash' 在庫を開く
RegisterNetEvent('jp-gacha:verifyAdminPassword', function(plain, purpose)
    local src = source
    if type(plain) ~= 'string' then
        TriggerClientEvent('jp-gacha:adminDenied', src)
        return
    end
    local p = tostring(purpose or 'admin')
    if plain == GetStoredAdminPassword() then
        AdminUnlocked[src] = true
        if p == 'stash' then
            TriggerClientEvent('jp-gacha:stashUnlocked', src)
        else
            SendAdminDataToClient(src)
        end
    else
        TriggerClientEvent('jp-gacha:adminDenied', src)
    end
end)

-- セッション中はパス再入力不要: 管理画面を開く
RegisterNetEvent('jp-gacha:requestOpenAdmin', function()
    local src = source
    if not AdminUnlocked[src] then
        TriggerClientEvent('jp-gacha:adminDenied', src)
        return
    end
    SendAdminDataToClient(src)
end)

-- セッション中: NUI から在庫スタッシュを開く（再認証不要）
RegisterNetEvent('jp-gacha:requestStashOpen', function()
    local src = source
    if not AdminUnlocked[src] then
        TriggerClientEvent('jp-gacha:adminDenied', src)
        return
    end
    TriggerClientEvent('jp-gacha:stashUnlocked', src)
end)

-- 管理パスワード変更（KVS）セッション中のみ
RegisterNetEvent('jp-gacha:changeAdminPassword', function(data)
    local src = source
    if not AdminUnlocked[src] then
        return
    end
    if type(data) ~= 'table' or type(data.current) ~= 'string' or type(data.newPassword) ~= 'string' then
        TriggerClientEvent('jp-gacha:changePasswordResult', src, { ok = false, reason = 'invalid' })
        return
    end
    if data.current ~= GetStoredAdminPassword() then
        TriggerClientEvent('jp-gacha:changePasswordResult', src, { ok = false, reason = 'mismatch' })
        return
    end
    if #data.newPassword < 1 then
        TriggerClientEvent('jp-gacha:changePasswordResult', src, { ok = false, reason = 'empty' })
        return
    end
    if SetStoredAdminPassword(data.newPassword) then
        TriggerClientEvent('jp-gacha:changePasswordResult', src, { ok = true })
    else
        TriggerClientEvent('jp-gacha:changePasswordResult', src, { ok = false, reason = 'save' })
    end
end)

RegisterNetEvent('jp-gacha:adminSessionEnd', function()
    local src = source
    AdminUnlocked[src] = nil
end)

RegisterNetEvent('jp-gacha:saveAdminData', function(data)
    local src = source
    if not AdminUnlocked[src] then
        if Config.Debug then
            print('[jp-gacha] saveAdminData: セッションなし ' .. tostring(src))
        end
        return
    end
    if type(data) ~= 'table' or type(data.rarityPct) ~= 'table' or type(data.items) ~= 'table' then
        TriggerClientEvent('jp-gacha:adminSaveResult', src, { ok = false, reason = 'invalid' })
        return
    end
    local vok, err = ValidateRarityTotal(data.rarityPct)
    if not vok then
        TriggerClientEvent('jp-gacha:adminSaveResult', src, { ok = false, reason = err or 'rarity' })
        return
    end
    GachaKvs.title = tostring(data.title or Config.MenuTitle)
    GachaKvs.cost = tonumber(data.cost) or Config.Cost
    GachaKvs.theme = tostring(data.theme or 'neon')
    GachaKvs.rarityPct = {
        UR = tonumber(data.rarityPct.UR) or 0,
        SSR = tonumber(data.rarityPct.SSR) or 0,
        SR = tonumber(data.rarityPct.SR) or 0,
        R = tonumber(data.rarityPct.R) or 0,
    }
    local nSet = {}
    for _, it in ipairs(data.items) do
        if it and it.id and type(it.id) == 'string' then
            local r = tostring(it.rarity or 'R')
            if r == 'N' or (r ~= 'R' and r ~= 'SR' and r ~= 'SSR' and r ~= 'UR') then
                r = 'R'
            end
            nSet[it.id] = {
                enabled = (it.enabled ~= false),
                rarity = r
            }
        end
    end
    GachaKvs.itemSettings = nSet
    SaveGachaKvs()
    LoadGachaKvs()
    TriggerClientEvent('jp-gacha:adminSaveResult', src, { ok = true })
end)

-- 複数回ガチャ対応（KVS 管理プール or Config フォールバック）
RegisterNetEvent('jp-gacha:requestMultiDraw', function(count)
    local source = source
    if type(source) == 'string' then
        source = tonumber(source)
    end
    if not source or source < 1 then
        return
    end
    count = math.floor(tonumber(count) or 0)
    if count < 1 or count > Config.MaxPullCount then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'invalid')
        return
    end
    local now = os.time()
    if PlayerCooldowns[source] and (now - PlayerCooldowns[source]) < Config.Cooldown then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'cooldown')
        return
    end
    local totalCost = GetEffectiveCost() * count
    if totalCost > 0 and not TryChargeMoney(source, totalCost) then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'nomoney')
        return
    end
    PlayerCooldowns[source] = now

    local canKvs = HasAnyEnablePool()
    if not canKvs and not Config.FallbackToConfigIfStashEmpty then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'invalid')
        return
    end
    local useKvs = canKvs

    -- 必ず pushResultRow より上で初期化（Lua では上にある関数内の `results` は
    -- 後方の `local` に束さないため、グローバル扱いになり nil 参照になる）
    local results = {}

    local function pushResultRow(i, b)
        results[i] = {
            index = i,
            rarityId = b.rarityId,
            rarityName = b.rarityName,
            rarityColor = b.rarityColor,
            capsule = b.capsule,
            bg = b.bg,
            cutin = b.cutin,
            itemName = b.itemName,
            itemImage = b.itemImage,
            itemSpawnName = b.itemSpawnName,
        }
    end
    for i = 1, count do
        if useKvs then
            local got = false
            for _t = 1, 32 do
                local cat = BuildPrizeCatalog()
                local roll = DrawFourTierRarity()
                local pick, vid = DrawOnePrize(roll, cat)
                if not pick then
                    if Config.FallbackToConfigIfStashEmpty then
                        local rar = DrawRarity()
                        local it = DrawItemFromConfig(rar.id)
                        local vrow = MapFourTierToRowId(rar.id)
                        if rar.id == 'N' then
                            vrow = 'R'
                        end
                        local b = BuildDrawResult({ name = it.name, label = it.name, image = it.image or '' }, vrow)
                        pushResultRow(i, b)
                    else
                        local b = BuildDrawResult(
                            { name = "在庫なし", label = "在庫なし", image = "" },
                            'R'
                        )
                        pushResultRow(i, b)
                    end
                    got = true
                    break
                end
                if pick.isOx then
                    if TransferOneFromStashToPlayer(source, pick.name) then
                        local b = BuildDrawResult(pick, vid)
                        pushResultRow(i, b)
                        got = true
                        break
                    end
                else
                    local b = BuildDrawResult(pick, vid)
                    pushResultRow(i, b)
                    got = true
                    break
                end
            end
            if not got then
                local b = BuildDrawResult(
                    { name = "在庫処理エラー", label = "在庫処理エラー", image = "" },
                    'R'
                )
                pushResultRow(i, b)
            end
        else
            local rarity = DrawRarity()
            local item = DrawItemFromConfig(rarity.id)
            local row = LegacyMultiDrawRow(rarity, item)
            row.index = i
            results[i] = row
        end
    end
    if count > 0 then
        for i, r in ipairs(results) do
            r.index = i
        end
    end

    TriggerClientEvent('jp-gacha:multiDrawResult', source, results, count)
    local playerName = GetPlayerName(source) or "Unknown"
    for _, r in ipairs(results) do
        print(('[jp-gacha] %s が %s（%s）を引いた'):format(playerName, r.itemName, r.rarityId))
    end
    local hasRare = false
    local rareItems = {}
    for _, r in ipairs(results) do
        if r.rarityId == 'SR' or r.rarityId == 'SSR' or r.rarityId == 'UR' then
            hasRare = true
            table.insert(rareItems, ('【%s】%s'):format(r.rarityName, r.itemName))
        end
    end
    if hasRare then
        TriggerClientEvent('chat:addMessage', -1, {
            color = { 255, 215, 0 },
            multiline = false,
            args = {
                "🎰 ガチャ",
                ('%s が %s を引き当てた！'):format(playerName, table.concat(rareItems, '、'))
            }
        })
    else
        local itemNames = {}
        for _, r in ipairs(results) do
            table.insert(itemNames, r.itemName)
        end
        TriggerClientEvent('chat:addMessage', source, {
            color = { 200, 200, 200 },
            multiline = false,
            args = {
                "🎰 ガチャ",
                ('%s を手に入れた'):format(table.concat(itemNames, '、'))
            }
        })
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if PlayerCooldowns then
        PlayerCooldowns[src] = nil
    end
    AdminUnlocked[src] = nil
end)
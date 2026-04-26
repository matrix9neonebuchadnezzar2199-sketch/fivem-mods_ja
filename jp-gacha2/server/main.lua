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

local function AdminAllowed(src)
    if not Config.RequireAdminAce then
        return true
    end
    local ac = tostring(Config.AdminCommand or 'gachaadmin')
    if IsPlayerAceAllowed(src, 'command.' .. ac) or IsPlayerAceAllowed(src, tostring(Config.AdminAce or 'jp-gacha2.admin')) then
        return true
    end
    return false
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
local function GetOxItemImageNui(name)
    if not name or GetResourceState('ox_inventory') ~= 'started' then
        return ''
    end
    return 'nui://ox_inventory/web/images/' .. tostring(name) .. '.png'
end

-- 景品候補カタログ: cfg:カテゴリ:行番号 / ox:itemname
local function BuildPrizeCatalog()
    local out = {}
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
    if GetResourceState('ox_inventory') == 'started' and Config.StashName then
        local ok, inv = pcall(function()
            return exports.ox_inventory:GetInventory(Config.StashName, false)
        end)
        if ok and inv and inv.items then
            local oxByName = {}
            for _slot, v in pairs(inv.items) do
                if v and v.name and (v.count or 0) > 0 then
                    local n = tostring(v.name)
                    if not oxByName[n] then
                        oxByName[n] = 0
                    end
                    oxByName[n] = oxByName[n] + (v.count or 0)
                end
            end
            for n, cnt in pairs(oxByName) do
                if cnt > 0 then
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

local function BuildDrawResult(pick, visualRarityId)
    local rrow = GetRarityRowById(visualRarityId) or GetRarityRowById('R') or Config.Rarities[1]
    return {
        rarityId = rrow.id,
        rarityName = rrow.name,
        rarityColor = rrow.color,
        capsule = rrow.capsule,
        bg = rrow.bg,
        cutin = rrow.cutin,
        itemName = (pick and pick.label) or (pick and pick.name) or '不明',
        itemImage = (pick and pick.image) or '',
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
    LoadGachaKvs()
end)

local PlayerCooldowns = {}

local function BuildMenuItemRows()
    local catalog = BuildPrizeCatalog()
    local probs, _nBy = ComputeItemProbabilities(catalog, GachaKvs.rarityPct)
    local rows = {}
    for _, e in ipairs(catalog) do
        local s = GetItemSetting(e.id) or DefaultSettingForEntry(e)
        if (not s.enabled) or (e.isOx and (e.count or 0) <= 0) then
            -- ガチャ表は排出 ON かつ在庫ありのみ
        else
            local prob = probs and probs[e.id] or 0
            rows[#rows + 1] = {
                id = e.id,
                name = e.name,
                label = e.label,
                count = e.isOx and (e.count or 0) or -1,
                image = e.image,
                enabled = s.enabled,
                rarity = s.rarity,
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

RegisterNetEvent('jp-gacha:requestAdminData', function()
    local src = source
    if not AdminAllowed(src) then
        if Config.Debug then
            print('[jp-gacha] requestAdminData denied: ' .. tostring(src))
        end
        return
    end
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
end)

RegisterNetEvent('jp-gacha:saveAdminData', function(data)
    local src = source
    if not AdminAllowed(src) then
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

    local catalog = BuildPrizeCatalog()
    local canKvs = HasAnyEnablePool()
    if not canKvs and not Config.FallbackToConfigIfStashEmpty then
        TriggerClientEvent('jp-gacha:drawDenied', source, 'invalid')
        return
    end
    local useKvs = canKvs

    local results = {}
    for i = 1, count do
        if useKvs then
            local roll = DrawFourTierRarity()
            local pick, vid = DrawOnePrize(roll, catalog)
            if not pick then
                local rar = DrawRarity()
                local it = DrawItemFromConfig(rar.id)
                local vrow = MapFourTierToRowId(rar.id)
                if rar.id == 'N' then
                    vrow = 'R'
                end
                local row = {
                    index = i,
                }
                local b = BuildDrawResult({ name = it.name, label = it.name, image = it.image or '' }, vrow)
                row.rarityId = b.rarityId
                row.rarityName = b.rarityName
                row.rarityColor = b.rarityColor
                row.capsule = b.capsule
                row.bg = b.bg
                row.cutin = b.cutin
                row.itemName = b.itemName
                row.itemImage = b.itemImage
                results[i] = row
            else
                local b = BuildDrawResult(pick, vid)
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
                }
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
    PlayerCooldowns[source] = nil
end)
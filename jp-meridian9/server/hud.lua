-- ============================================================
-- jp-meridian9 / server/hud.lua
-- ============================================================
-- 任務中 Phase-C HUD: 1 秒周期で `jp-meridian9:client:hud:state` 配信。
-- パーティは他メンバー名のみ。LOOT 集計・メトリクスはサーバ権威。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.HUD = MRD9.HUD or {}

local hudThreadRunning = false

---@param src integer
---@return string
local function getCharacterName(src)
    if MRD9.Framework and MRD9.Framework.GetCharacterName then
        local n = MRD9.Framework.GetCharacterName(src)
        if type(n) == 'string' and n ~= '' then
            return n
        end
    end
    local gn = GetPlayerName(src)
    if type(gn) == 'string' and gn ~= '' then
        return gn
    end
    return ('Player %d'):format(src)
end

---@param session table
---@param viewerSrc integer
---@return table[]
function MRD9.HUD.GetPartyState(session, viewerSrc)
    local list = {}
    for _, m in ipairs(session.members or {}) do
        if m ~= viewerSrc then
            list[#list + 1] = {
                id = m,
                name = getCharacterName(m),
                leader = (session.leader == m),
                status = 'alive',
            }
        end
    end
    table.sort(list, function(a, b)
        if a.leader ~= b.leader then
            return a.leader
        end
        return a.id < b.id
    end)
    return list
end

---@param session table
---@param viewerSrc integer|nil
---@return table
function MRD9.HUD.GetMetrics(session, viewerSrc)
    local cfg = Config.HUD or {}
    local mode = cfg.lootMetricMode or 'L2'
    local warnSec = tonumber(cfg.extractWarningSec) or 60
    local loot = { current = 0, max = 0 }

    if mode == 'L1' then
        local inv = session.inventory and viewerSrc and session.inventory[viewerSrc]
        local flat = MRD9.FlattenMissionInventory and MRD9.FlattenMissionInventory(inv or {}) or {}
        for _, c in pairs(flat) do
            loot.current = loot.current + math.floor(tonumber(c) or 0)
        end
        loot.max = math.floor(tonumber(cfg.personalLootCap) or 99)
    else
        local remaining = 0
        for _, slot in pairs(session.loot or {}) do
            if type(slot) == 'table' and not slot.picked then
                remaining = remaining + 1
            end
        end
        local initial = math.floor(tonumber(session.lootInitialCount) or 0)
        loot.current = math.max(0, initial - remaining)
        loot.max = initial
    end

    local extractSec = 0
    if session.endsAt and type(session.endsAt) == 'number' then
        extractSec = math.max(0, math.floor((session.endsAt - GetGameTimer()) / 1000))
    end

    local zs = session.zombieState or {}
    local killCur = math.floor(tonumber(zs.totalKilled) or 0)
    local killTarget = math.floor(tonumber(cfg.killDisplayTarget) or 30)
    if session.mission and session.mission.killTarget then
        killTarget = math.floor(tonumber(session.mission.killTarget) or killTarget)
    end

    return {
        kills = { current = killCur, target = killTarget },
        loot = { current = loot.current, max = loot.max },
        extractSeconds = extractSec,
        extractWarningSec = warnSec,
    }
end

---@param session table
---@return table[]
function MRD9.HUD.GetLootList(session)
    local agg = {}
    for _, memberSrc in ipairs(session.members or {}) do
        local inv = session.inventory and session.inventory[memberSrc]
        if inv then
            local flat = MRD9.FlattenMissionInventory and MRD9.FlattenMissionInventory(inv) or {}
            for itemId, count in pairs(flat) do
                count = math.floor(tonumber(count) or 0)
                if type(itemId) == 'string' and count > 0 then
                    local def = MRD9.Loot and MRD9.Loot.FindItemDef and MRD9.Loot.FindItemDef(itemId)
                    if not agg[itemId] then
                        local r = (def and def.rarity) or 'common'
                        local fiction = def and type(def.fictionTag) == 'string' and def.fictionTag ~= ''
                        agg[itemId] = {
                            itemId = itemId,
                            nameKey = (def and def.nameKey) or nil,
                            label = (def and def.name) or itemId,
                            tier = r,
                            count = 0,
                            confiscated = fiction,
                        }
                    end
                    agg[itemId].count = agg[itemId].count + count
                end
            end
        end
    end
    local list = {}
    for _, v in pairs(agg) do
        list[#list + 1] = v
    end
    local order = { legendary = 1, rare = 2, uncommon = 3, common = 4 }
    table.sort(list, function(a, b)
        if a.confiscated ~= b.confiscated then
            return not a.confiscated
        end
        return (order[a.tier] or 99) < (order[b.tier] or 99)
    end)
    return list
end

---@param session table
---@return string
local function missionTitleFor(session)
    local m = session.mission or {}
    local t = m.title or m.type or 'RECOVERY'
    return ('サイト・ナイン / %s'):format(tostring(t))
end

---@param session table
---@param recipientSrc integer
---@return table
local function buildPhaseCPayload(session, recipientSrc)
    local now = os.date('*t')
    local clock = ('%02d:%02d'):format(now.hour, now.min)
    return {
        mission = {
            title = missionTitleFor(session),
            contractId = session.contractId or session.id or '',
        },
        self = { name = getCharacterName(recipientSrc) },
        party = MRD9.HUD.GetPartyState(session, recipientSrc),
        loot = MRD9.HUD.GetLootList(session),
        metrics = MRD9.HUD.GetMetrics(session, recipientSrc),
        clock = clock,
    }
end

local function broadcastSessionHud(session)
    if not session or not session.members then
        return
    end
    for _, m in ipairs(session.members) do
        local payload = buildPhaseCPayload(session, m)
        TriggerClientEvent('jp-meridian9:client:hud:state', m, payload)
    end
end

local function hudTickLoop()
    if hudThreadRunning then
        return
    end
    hudThreadRunning = true
    CreateThread(function()
        while hudThreadRunning do
            local cfg = Config.HUD or {}
            local tickMs = tonumber(cfg.stateBroadcastIntervalMs)
                or tonumber(cfg.tickServerMs)
                or tonumber(cfg.updateInterval)
                or 1000
            local any = false
            local all = MRD9.Session and MRD9.Session.GetAll and MRD9.Session.GetAll() or {}
            for _, s in pairs(all) do
                if s.state == 'IN_MISSION' and s.members and #s.members > 0 then
                    any = true
                    broadcastSessionHud(s)
                end
            end
            Wait(any and tickMs or 2000)
        end
    end)
end

function MRD9.HUD.Start()
    if not Config.HUD or Config.HUD.enabled == false then
        return
    end
    hudTickLoop()
end

---@param session table|nil
---@param leavingSrc integer
---@param nuiReason string @'dead' | 'disconnected'
function MRD9.HUD.NotifyPartyLeave(session, leavingSrc, nuiReason)
    if not session or not session.members or type(leavingSrc) ~= 'number' then
        return
    end
    if nuiReason ~= 'dead' and nuiReason ~= 'disconnected' then
        return
    end
    local name = getCharacterName(leavingSrc)
    for _, m in ipairs(session.members) do
        if m ~= leavingSrc then
            TriggerClientEvent('jp-meridian9:client:hud:partyLeave', m, {
                memberId = leavingSrc,
                name = name,
                reason = nuiReason,
            })
        end
    end
end

---@param src integer
---@param itemId string
function MRD9.HUD.NotifyPickup(src, itemId)
    if type(src) ~= 'number' or src <= 0 or type(itemId) ~= 'string' or itemId == '' then
        return
    end
    local def = MRD9.Loot and MRD9.Loot.FindItemDef and MRD9.Loot.FindItemDef(itemId)
    if not def then
        return
    end
    local fiction = type(def.fictionTag) == 'string' and def.fictionTag ~= ''
    TriggerClientEvent('jp-meridian9:client:hud:pickup', src, {
        itemId = itemId,
        nameKey = def.nameKey,
        label = def.name or itemId,
        tier = def.rarity or 'common',
        confiscated = fiction,
    })
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    hudThreadRunning = false
end)

CreateThread(function()
    Wait(2000)
    MRD9.HUD.Start()
end)

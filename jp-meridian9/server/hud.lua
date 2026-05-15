-- ============================================================
-- jp-meridian9 / server/hud.lua
-- ============================================================
-- 任務中 HUD 用 DTO 配信（サーバー権威の HP / インベントリ集計）。
-- INSTRUCTION-014（Q1=a）
-- ============================================================

MRD9 = MRD9 or {}
MRD9.HUD = MRD9.HUD or {}

local hudThreadRunning = false

---@param itemId string
---@return table|nil
local function findItemDef(itemId)
    for _, it in ipairs(Config.Items or {}) do
        if it.id == itemId then
            return it
        end
    end
    return nil
end

---@param session table
---@param src integer
---@return table
local function buildInventoryFor(session, src)
    local inv = session.inventory and session.inventory[src] or {}
    local total = 0
    local byRarity = {
        common = 0,
        uncommon = 0,
        rare = 0,
        legendary = 0,
    }
    for itemId, qty in pairs(inv) do
        if type(itemId) == 'string' and type(qty) == 'number' and qty > 0 then
            total = total + qty
            local def = findItemDef(itemId)
            local r = (def and def.rarity) or 'common'
            if byRarity[r] then
                byRarity[r] = byRarity[r] + qty
            else
                byRarity.common = byRarity.common + qty
            end
        end
    end
    return { total = total, byRarity = byRarity }
end

---@param session table
---@param src integer
---@return table[]
local function buildMembersArray(session, src)
    local list = {}
    for _, m in ipairs(session.members or {}) do
        local ped = GetPlayerPed(m)
        local hp, maxHp, armor = 0, 200, 0
        local alive = false
        if ped and ped ~= 0 then
            hp = GetEntityHealth(ped) or 0
            maxHp = math.max(1, GetEntityMaxHealth(ped) or 200)
            armor = GetPedArmour(ped) or 0
            alive = hp > 0
        end
        local name = GetPlayerName(m)
        if type(name) ~= 'string' or name == '' then
            name = ('#%d'):format(m)
        end
        list[#list + 1] = {
            src = m,
            name = name,
            hp = hp,
            maxHp = maxHp,
            armor = armor,
            alive = alive,
            isLeader = m == session.leader,
            isSelf = m == src,
        }
    end
    table.sort(list, function(a, b)
        if a.isSelf ~= b.isSelf then
            return a.isSelf
        end
        if a.isLeader ~= b.isLeader then
            return a.isLeader
        end
        return a.src < b.src
    end)
    return list
end

---@param session table
---@param recipientSrc integer
---@return table
local function buildDto(session, recipientSrc)
    local now = GetGameTimer()
    local timerSec = 0
    if session.endsAt and type(session.endsAt) == 'number' then
        timerSec = math.max(0, math.floor((session.endsAt - now) / 1000))
    end

    local ped = GetPlayerPed(recipientSrc)
    local shp, smax, sarm = 0, 200, 0
    if ped and ped ~= 0 then
        shp = GetEntityHealth(ped) or 0
        smax = math.max(1, GetEntityMaxHealth(ped) or 200)
        sarm = GetPedArmour(ped) or 0
    end

    local arena = { active = false, wave = 0, totalWaves = 3, zombiesAlive = 0 }
    if MRD9.Arena and MRD9.Arena.GetHudSnapshot then
        arena = MRD9.Arena.GetHudSnapshot(session.id)
    end

    return {
        sessionId = session.id,
        timerSec = timerSec,
        self = { hp = shp, maxHp = smax, armor = sarm },
        members = buildMembersArray(session, recipientSrc),
        inventory = buildInventoryFor(session, recipientSrc),
        arena = arena,
    }
end

local function broadcastSessionHud(session)
    if not session or not session.members then
        return
    end
    for _, m in ipairs(session.members) do
        local dto = buildDto(session, m)
        TriggerClientEvent('jp-meridian9:client:hud:state', m, dto)
    end
end

local function hudTickLoop()
    if hudThreadRunning then
        return
    end
    hudThreadRunning = true
    CreateThread(function()
        local cfg = Config.HUD or {}
        while hudThreadRunning do
            local tickMs = tonumber(cfg.tickServerMs) or tonumber(cfg.updateInterval) or 500
            local any = false
            local all = MRD9.Session and MRD9.Session.GetAll and MRD9.Session.GetAll() or {}
            for _, s in pairs(all) do
                if s.state == 'IN_MISSION' then
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

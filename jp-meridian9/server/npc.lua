-- ============================================================
-- MERIDIAN-9 / NPC インタラクション（サーバ検証・INSTRUCTION-022）
-- クライアントの E 押下は必ず本イベント経由。受注 UI 本体はクライアント既存のまま。
-- ============================================================

MRD9 = MRD9 or {}

local lastInteractAt = {} ---@type table<integer, integer>

---@param npcId string
---@return vector3|nil
local function resolveNpcCoords(npcId)
    local npc = Config.NPC
    if not npc then
        return nil
    end
    local pt = npc.points and npc.points[npcId]
    if pt and pt.coords then
        local c = pt.coords
        return vector3(c.x, c.y, c.z)
    end
    if npcId == 'vega' and npc.coords then
        local c = npc.coords
        return vector3(c.x, c.y, c.z)
    end
    return nil
end

---@param npcId string
---@return boolean
local function isNpcEnabled(npcId)
    local pt = Config.NPC and Config.NPC.points and Config.NPC.points[npcId]
    if pt and pt.enabled == false then
        return false
    end
    return true
end

---@param src integer
---@param npcId string
---@return boolean
local function validateDistance(src, npcId)
    local ic = Config.NPC and Config.NPC.interact
    if not ic then
        return false
    end
    local npcCoords = resolveNpcCoords(npcId)
    if not npcCoords then
        return false
    end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return false
    end
    local pcoords = GetEntityCoords(ped)
    local dx = pcoords.x - npcCoords.x
    local dy = pcoords.y - npcCoords.y
    local dz = math.abs(pcoords.z - npcCoords.z)
    local dist2d = math.sqrt(dx * dx + dy * dy)
    local max2d = (tonumber(ic.triggerDistance) or 2.0) + 1.0
    if dist2d > max2d or dz > 5.0 then
        return false
    end
    return true
end

RegisterNetEvent('mrd9:npc:interact', function(npcId)
    local src = source
    if not src or src <= 0 then
        return
    end
    if type(npcId) ~= 'string' or npcId == '' then
        return
    end
    if not isNpcEnabled(npcId) then
        return
    end

    local ic = Config.NPC and Config.NPC.interact
    local cd = ic and tonumber(ic.cooldownMs) or 800
    local now = GetGameTimer()
    if (lastInteractAt[src] or 0) + cd > now then
        return
    end

    if not validateDistance(src, npcId) then
        print(('[jp-meridian9] npc interact rejected: src=%d npcId=%s reason=distance'):format(src, npcId))
        return
    end

    lastInteractAt[src] = now
    TriggerClientEvent('jp-meridian9:client:openDialogue', src)
end)

AddEventHandler('playerDropped', function()
    local src = source
    if src and src > 0 then
        lastInteractAt[src] = nil
    end
end)

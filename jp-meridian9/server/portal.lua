-- ============================================================
-- MERIDIAN-9 / ポータル演出の ON/OFF 同期（INSTRUCTION-022）
-- 任務開始は NPC のみ。ここでは見た目の有効フラグのみ管理する。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.Portal = MRD9.Portal or {}

---@type table<string, boolean>
local stateById = {}

---@return table<string, boolean>
local function buildDefaultState()
    local t = {}
    local cfg = Config.Portals
    if cfg and type(cfg.points) == 'table' then
        for _, pt in ipairs(cfg.points) do
            if type(pt) == 'table' and type(pt.id) == 'string' and pt.id ~= '' then
                t[pt.id] = true
            end
        end
    end
    return t
end

function MRD9.Portal.GetAllStates()
    return stateById
end

---@param id string
---@return boolean
function MRD9.Portal.IsOn(id)
    if stateById[id] == false then
        return false
    end
    return true
end

---@param id string
---@param on boolean
local function setStateInternal(id, on)
    if type(id) ~= 'string' or id == '' then
        return
    end
    stateById[id] = on and true or false
    local ev = MRD9.PortalDefs and MRD9.PortalDefs.netSetState or 'mrd9:portal:setState'
    TriggerClientEvent(ev, -1, id, stateById[id])
end

---@param tbl table<string, boolean>|nil
local function applyFullSync(tbl)
    stateById = {}
    local defaults = buildDefaultState()
    for id, _ in pairs(defaults) do
        stateById[id] = true
    end
    if type(tbl) == 'table' then
        for id, v in pairs(tbl) do
            if type(id) == 'string' then
                stateById[id] = v and true or false
            end
        end
    end
    local ev = MRD9.PortalDefs and MRD9.PortalDefs.netSyncAll or 'mrd9:portal:syncAll'
    TriggerClientEvent(ev, -1, stateById)
end

RegisterNetEvent('mrd9:portal:requestSync', function()
    local src = source
    if not src or src <= 0 then
        return
    end
    local ev = MRD9.PortalDefs and MRD9.PortalDefs.netSyncAll or 'mrd9:portal:syncAll'
    TriggerClientEvent(ev, src, stateById)
end)

local function adminAceName()
    return (Config.Admin and Config.Admin.aceName) or 'jp-meridian9.admin'
end

---@param source integer
---@return boolean
local function HasAdminAce(source)
    if source == 0 then
        return true
    end
    return IsPlayerAceAllowed(source, adminAceName()) == true
end

---@param source integer
---@param msg string
local function notifyAdmin(source, msg)
    if source == 0 then
        print(('[MRD9 PORTAL] %s'):format(msg))
        return
    end
    TriggerClientEvent('chat:addMessage', source, {
        color = { 200, 180, 255 },
        multiline = true,
        args = { '[MRD9 PORTAL]', msg },
    })
end

CreateThread(function()
    Wait(500)
    applyFullSync(nil)
end)

RegisterCommand('m9_portal', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local id = args[1]
    local mode = args[2]
    if not id or not mode then
        notifyAdmin(source, '使用方法: /m9_portal <id> on|off')
        return
    end
    local on = mode:lower() == 'on'
    if mode:lower() ~= 'on' and mode:lower() ~= 'off' then
        notifyAdmin(source, '第2引数は on または off')
        return
    end
    setStateInternal(id, on)
    notifyAdmin(source, ('ポータル %s → %s'):format(id, on and 'ON' or 'OFF'))
end, false)

RegisterCommand('m9_portal_all', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local mode = args[1]
    if not mode then
        notifyAdmin(source, '使用方法: /m9_portal_all on|off')
        return
    end
    local on = mode:lower() == 'on'
    if mode:lower() ~= 'on' and mode:lower() ~= 'off' then
        notifyAdmin(source, '引数は on または off')
        return
    end
    local cfg = Config.Portals
    if cfg and type(cfg.points) == 'table' then
        for _, pt in ipairs(cfg.points) do
            if type(pt) == 'table' and type(pt.id) == 'string' then
                stateById[pt.id] = on and true or false
            end
        end
    end
    local ev = MRD9.PortalDefs and MRD9.PortalDefs.netSyncAll or 'mrd9:portal:syncAll'
    TriggerClientEvent(ev, -1, stateById)
    notifyAdmin(source, '全ポータル → ' .. (on and 'ON' or 'OFF'))
end, false)

RegisterCommand('m9_portal_list', function(source, args)
    if not HasAdminAce(source) then
        return
    end
    local lines = {}
    for id, v in pairs(stateById) do
        lines[#lines + 1] = ('%s = %s'):format(id, v and 'on' or 'off')
    end
    table.sort(lines)
    notifyAdmin(source, #lines > 0 and table.concat(lines, '\n') or '(状態なし)')
end, false)

RegisterCommand('m9_portal_tp', function(source, args)
    if not Config.Debug then
        if source ~= 0 then
            notifyAdmin(source, '/m9_portal_tp は Config.Debug=true のときのみ使用可能')
        end
        return
    end
    if not HasAdminAce(source) then
        return
    end
    if source == 0 then
        print('[jp-meridian9] /m9_portal_tp はゲーム内プレイヤーから実行してください')
        return
    end
    local id = args[1]
    if not id then
        notifyAdmin(source, '使用方法: /m9_portal_tp <id>')
        return
    end
    local cfg = Config.Portals
    if not cfg or type(cfg.points) ~= 'table' then
        return
    end
    for _, pt in ipairs(cfg.points) do
        if type(pt) == 'table' and pt.id == id and pt.coords then
            local c = pt.coords
            local ped = GetPlayerPed(source)
            if ped and ped ~= 0 then
                SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
            end
            notifyAdmin(source, ('テレポート: %s'):format(id))
            return
        end
    end
    notifyAdmin(source, 'ID が見つかりません: ' .. id)
end, false)

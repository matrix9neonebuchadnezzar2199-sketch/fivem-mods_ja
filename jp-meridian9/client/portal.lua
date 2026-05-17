-- ============================================================
-- MERIDIAN-9 / ポータル演出クライアント（INSTRUCTION-022）
-- 装飾のみ。ox_target なし。サーバの ON/OFF に追従。
-- ============================================================

MRD9 = MRD9 or {}

local State = {
    byId = {}, ---@type table<string, boolean>
}

---@param id string
---@return boolean
local function isPortalOn(id)
    if State.byId[id] == false then
        return false
    end
    return true
end

local function eventSetState()
    return (MRD9.PortalDefs and MRD9.PortalDefs.netSetState) or 'mrd9:portal:setState'
end

local function eventSyncAll()
    return (MRD9.PortalDefs and MRD9.PortalDefs.netSyncAll) or 'mrd9:portal:syncAll'
end

local function eventRequestSync()
    return (MRD9.PortalDefs and MRD9.PortalDefs.netRequestSync) or 'mrd9:portal:requestSync'
end

RegisterNetEvent('mrd9:portal:setState', function(id, on)
    if type(id) ~= 'string' or id == '' then
        return
    end
    State.byId[id] = on and true or false
end)

RegisterNetEvent('mrd9:portal:syncAll', function(tbl)
    if type(tbl) == 'table' then
        State.byId = tbl
    else
        State.byId = {}
    end
end)

CreateThread(function()
    Wait(1500)
    TriggerServerEvent(eventRequestSync())
end)

---@param z number
---@param amp number
---@param hz number
---@return number
local function bobOffset(z, amp, hz)
    local t = GetGameTimer() / 1000.0
    return z + math.sin(t * hz * 6.2831853) * amp
end

CreateThread(function()
    while true do
        local cfg = Config.Portals
        if not cfg or cfg.enabled == false then
            Wait(1000)
        else
            local ped = PlayerPedId()
            local pcoords = GetEntityCoords(ped)
            local lod = (cfg.lod and cfg.lod.maxDrawDistance) or 80.0
            local haze = cfg.haze
            local sleep = 750
            local drew = false

            if haze and haze.enabled ~= false and type(cfg.points) == 'table' then
                for _, pt in ipairs(cfg.points) do
                    if type(pt) == 'table' and type(pt.id) == 'string' and pt.coords and isPortalOn(pt.id) then
                        local c = pt.coords
                        local dist = #(pcoords - vector3(c.x, c.y, c.z))
                        if dist < lod then
                            sleep = 0
                            drew = true
                            local mtype = tonumber(haze.markerType) or 28
                            local sc = haze.scale or { x = 1.5, y = 1.5, z = 0.4 }
                            local rgba = haze.rgba or { r = 140, g = 60, b = 220, a = 100 }
                            local z = bobOffset(c.z, tonumber(haze.bobAmp) or 0.1, tonumber(haze.bobHz) or 0.35)
                            DrawMarker(
                                mtype,
                                c.x, c.y, z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                sc.x, sc.y, sc.z,
                                rgba.r, rgba.g, rgba.b, rgba.a,
                                false, false, 2, false, nil, nil, false
                            )
                        end
                    end
                end
            end

            if not drew then
                Wait(sleep > 0 and sleep or 500)
            else
                Wait(0)
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    State.byId = {}
end)

-- ============================================================
-- jp-meridian9 / server/playarea.lua
-- ============================================================
-- 任務中プレイヤーの座標を 2 秒周期で監視し、Config.Mission.playArea の
-- 中心から maxRadius を超えていたら警告 → graceSec 経過後 'out_of_zone' で除外する。
--
-- ヘリ・船などで脱出ポイントから離れすぎるパワープレイへの対策。
-- 警告は NUI トーストで通知する（既存の `jp-meridian9:notify` に乗せる）。
-- ============================================================

MRD9 = MRD9 or {}
MRD9.PlayArea = MRD9.PlayArea or {}

---@return table|nil
local function cfg()
    local m = Config and Config.Mission
    if type(m) ~= 'table' then
        return nil
    end
    local pa = m.playArea
    if type(pa) ~= 'table' or pa.enabled == false then
        return nil
    end
    if type(pa.center) ~= 'vector3' and not (type(pa.center) == 'table' and pa.center.x) then
        return nil
    end
    return pa
end

---@param session table
---@param src integer
---@return number|nil distance, vector3|nil pcoords
local function distanceFromCenter(session, src, pa)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then
        return nil, nil
    end
    local pc = GetEntityCoords(ped)
    if not pc then
        return nil, nil
    end
    local c = pa.center
    return #(pc - vector3(c.x, c.y, c.z)), pc
end

local running = false

local function tickLoop()
    if running then
        return
    end
    running = true
    CreateThread(function()
        while running do
            local pa = cfg()
            local interval = (pa and tonumber(pa.checkIntervalMs)) or 2000
            if not pa then
                Wait(5000)
            else
                local any = false
                local maxR = tonumber(pa.maxRadius) or 1200.0
                local warnSec = tonumber(pa.warnSec) or 20
                local graceSec = tonumber(pa.graceSec) or 30
                local sessions = MRD9.Session and MRD9.Session.GetAll and MRD9.Session.GetAll() or {}
                local now = GetGameTimer()
                for _, s in pairs(sessions) do
                    if s.state == 'IN_MISSION' and type(s.members) == 'table' then
                        any = true
                        s._playArea = s._playArea or {}
                        for _, src in ipairs(s.members) do
                            local dist = distanceFromCenter(s, src, pa)
                            if dist then
                                local entry = s._playArea[src]
                                if dist > maxR then
                                    if not entry then
                                        entry = { firstOutAt = now, warned = false, evicting = false }
                                        s._playArea[src] = entry
                                    end
                                    local outSec = math.floor((now - entry.firstOutAt) / 1000)
                                    if not entry.warned and outSec >= 0 then
                                        entry.warned = true
                                        TriggerClientEvent('jp-meridian9:notify', src,
                                            '指定区域から離脱しすぎている。30秒以内に戻れ。')
                                    end
                                    if not entry.evicting and outSec >= (warnSec + graceSec) then
                                        entry.evicting = true
                                        MRD9.Log('PlayArea evict src=%d session=%s dist=%.1f', src, s.id, dist)
                                        if MRD9.Session and MRD9.Session.RemovePlayer then
                                            MRD9.Session.RemovePlayer(src, 'out_of_zone')
                                        end
                                    elseif entry.warned and not entry.evicting then
                                        -- 中盤警告（10秒前後）
                                        local remain = (warnSec + graceSec) - outSec
                                        if remain == 10 then
                                            TriggerClientEvent('jp-meridian9:notify', src,
                                                ('あと %d 秒で契約違反による排除が発動する。'):format(remain))
                                        end
                                    end
                                else
                                    if entry then
                                        s._playArea[src] = nil
                                    end
                                end
                            end
                        end
                    end
                end
                Wait(any and interval or 5000)
            end
        end
    end)
end

function MRD9.PlayArea.Start()
    tickLoop()
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then
        return
    end
    running = false
end)

CreateThread(function()
    Wait(2500)
    MRD9.PlayArea.Start()
end)

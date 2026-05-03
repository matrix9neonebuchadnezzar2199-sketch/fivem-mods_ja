local JB = Config._JpSentinel.JobBridge

local Tracker = {}
local Loops = {}

---@param sentinelId string
function Tracker.Start(sentinelId)
    if Loops[sentinelId] then
        return
    end
    Loops[sentinelId] = true
    CreateThread(function()
        while Loops[sentinelId] do
            local active = Config._JpSentinel.ActiveSentinels
            local s = active and active[sentinelId]
            if not s then
                break
            end

            local remain = s.endTime - os.time()
            if remain <= 0 then
                break
            end

            local coords = s.lastCoords
            if coords then
                local police = JB.GetAllPoliceSources()
                for _, pid in ipairs(police) do
                    TriggerClientEvent('jp-sentinel:client:updateBlip', pid, {
                        sentinelId = sentinelId,
                        coords = coords,
                        remainSec = remain,
                        indoor = s.lastIndoor or false,
                    })
                end
            end

            Wait(Config.Blip.UpdateInterval)
        end
        Loops[sentinelId] = nil
    end)
end

---@param sentinelId string
function Tracker.Stop(sentinelId)
    Loops[sentinelId] = nil
end

Config._JpSentinel.Tracker = Tracker

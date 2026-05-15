-- ============================================================
-- jp-meridian9 / client/extract.lua
-- ============================================================
-- 脱出ポイント表示・近接判定・progressCircle・キャンセル監視。
-- ============================================================

MRD9 = MRD9 or {}

local resName = GetCurrentResourceName()

local State = {
    blips = {},
    activeIdx = nil,
    inProgress = false,
    cancelled = false,
    cancelReason = nil,
    proximityRunning = false,
    textUiOpen = false,
}

---@param b integer|nil
---@return nil
local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

local function clearBlips()
    for i, b in pairs(State.blips) do
        State.blips[i] = removeBlipSafe(b)
    end
    State.blips = {}
end

local function hideTextUI()
    if State.textUiOpen then
        State.textUiOpen = false
        if lib and lib.hideTextUI then
            lib.hideTextUI()
        end
    end
end

---@param idx integer
---@param pt table
local function createBlipFor(idx, pt)
    if not pt or not pt.coords then
        return
    end
    local c = pt.coords
    local b = AddBlipForCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    SetBlipSprite(b, tonumber(pt.blipSprite) or 488)
    SetBlipColour(b, tonumber(pt.blipColor) or 5)
    SetBlipScale(b, tonumber(pt.blipScale) or 0.85)
    SetBlipAsShortRange(b, pt.shortRange == true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(_('extract_blip_name', pt.label or ('#' .. idx)))
    EndTextCommandSetBlipName(b)
    State.blips[idx] = b
end

local function showBlips()
    clearBlips()
    local cfg = Config.Extract
    if not cfg or cfg.showBlipsDuringMission == false then
        return
    end
    local points = Config.ExtractPoints or {}
    for i, pt in ipairs(points) do
        createBlipFor(i, pt)
    end
end

---@param pedCoords vector3
---@return integer|nil, table|nil, number|nil
local function nearestExtractPoint(pedCoords)
    local points = Config.ExtractPoints or {}
    local bestIdx, bestPt, bestDist = nil, nil, math.huge
    for i, pt in ipairs(points) do
        if pt and pt.coords then
            local d = #(pedCoords - pt.coords)
            local r = tonumber(pt.radius) or 3.0
            if d <= r and d < bestDist then
                bestIdx, bestPt, bestDist = i, pt, d
            end
        end
    end
    return bestIdx, bestPt, bestDist
end

---@return boolean
local function ensureProgressLib()
    return lib and (lib.progressCircle or lib.progressBar) ~= nil
end

---@param idx integer
---@param pt table
local function runExtract(idx, pt)
    if State.inProgress or not ensureProgressLib() then
        return
    end
    local cfg = Config.Extract
    State.inProgress = true
    State.cancelled = false
    State.cancelReason = nil
    State.activeIdx = idx

    local duration = tonumber(cfg and cfg.durationMs) or 5000
    local startMs = GetGameTimer()
    local radius = tonumber(pt.radius) or 3.0
    local cancelOnDamage = cfg and cfg.cancelOnDamage ~= false

    CreateThread(function()
        while State.inProgress and not State.cancelled do
            local ped = PlayerPedId()
            if not ped or ped == 0 or IsPedDeadOrDying(ped, true) then
                State.cancelled = true
                State.cancelReason = 'died'
                break
            end
            if cancelOnDamage and HasEntityBeenDamagedByAnyPed(ped) then
                State.cancelled = true
                State.cancelReason = 'damage'
                break
            end
            local c = GetEntityCoords(ped)
            if #(c - pt.coords) > radius + 0.5 then
                State.cancelled = true
                State.cancelReason = 'out_of_zone'
                break
            end
            if (GetGameTimer() - startMs) >= duration then
                break
            end
            Wait(150)
        end
    end)

    ClearEntityLastDamageEntity(PlayerPedId())

    local circle = nil
    if lib.progressCircle then
        circle = lib.progressCircle({
            label = _('extract_progress_label', pt.label or ''),
            duration = duration,
            position = (cfg and cfg.textUiPosition) or 'middle',
            useWhileDead = false,
            canCancel = true,
            disable = {
                move = true,
                car = true,
                combat = true,
                sprint = true,
            },
            anim = {
                dict = 'random@arrests',
                clip = 'idle_2_hands_up',
            },
        })
    else
        circle = lib.progressBar({
            label = _('extract_progress_label', pt.label or ''),
            duration = duration,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
        })
    end

    local cancelled = State.cancelled or (not circle)
    local reason = State.cancelReason
    State.inProgress = false
    State.activeIdx = nil

    if cancelled then
        lib.notify({
            type = 'error',
            description = _('extract_cancel_' .. (reason or 'unknown'), pt.label or ''),
        })
        return
    end

    local res = lib.callback.await('jp-meridian9:extract:request', false, idx)
    if type(res) == 'table' and res.ok then
        lib.notify({
            type = 'success',
            description = _('extract_success', pt.label or ''),
        })
    else
        local r = type(res) == 'table' and res.reason or 'unknown'
        local key = 'extract_err_' .. tostring(r)
        local msg = _(key)
        if msg == key then
            msg = _('extract_err_unknown')
        end
        lib.notify({ type = 'error', description = msg })
    end
end

local function startProximity()
    if State.proximityRunning then
        return
    end
    State.proximityRunning = true
    CreateThread(function()
        while State.proximityRunning and MRD9.CurrentSession do
            local ped = PlayerPedId()
            if not ped or ped == 0 then
                Wait(800)
            else
                local idx, pt, _dist = nearestExtractPoint(GetEntityCoords(ped))
                if pt and not State.inProgress then
                    if not State.textUiOpen then
                        State.textUiOpen = true
                        lib.showTextUI(_('extract_textui_prompt', pt.label or ''), {
                            position = (Config.Extract and Config.Extract.textUiPosition) or 'right-center',
                            icon = 'right-from-bracket',
                        })
                    end
                    if IsControlJustReleased(0, 38) then
                        hideTextUI()
                        runExtract(idx, pt)
                    end
                    Wait(0)
                else
                    if State.textUiOpen then
                        hideTextUI()
                    end
                    Wait(500)
                end
            end
        end
        State.proximityRunning = false
        hideTextUI()
    end)
end

RegisterNetEvent('jp-meridian9:onMissionStart', function()
    showBlips()
    startProximity()
end)

RegisterNetEvent('jp-meridian9:onMissionEnd', function()
    State.proximityRunning = false
    State.inProgress = false
    hideTextUI()
    clearBlips()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= resName then
        return
    end
    State.proximityRunning = false
    hideTextUI()
    clearBlips()
end)

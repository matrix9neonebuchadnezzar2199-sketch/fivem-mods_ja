-- ============================================================
-- ヴェガ NPC スポーンと管理（INSTRUCTION-022: E キー＋TextUI）
-- ============================================================

MRD9 = MRD9 or {}
MRD9.NPC = MRD9.NPC or {}

local vegaPed = nil
local vegaBlip = nil

---@return boolean
function MRD9.NPC.IsVegaSpawned()
    return vegaPed ~= nil and vegaPed ~= 0 and DoesEntityExist(vegaPed) == true
end

---@class Mrd9NpcEntry
---@field id string
---@field entity integer
---@field coords vector3
---@field heading number
---@field label string
---@field enabled boolean

local NpcState = {
    registry = {}, ---@type table<string, Mrd9NpcEntry>
    nearIds = {}, ---@type string[]
    lastNearSig = '',
    textUiShown = false,
    lastPromptKey = '',
    clientCooldownUntil = 0,
}

---@param b integer|nil
---@return nil
local function removeBlipSafe(b)
    if b and DoesBlipExist(b) then
        RemoveBlip(b)
    end
    return nil
end

local function hidePrompt()
    if NpcState.textUiShown then
        lib.hideTextUI()
        NpcState.textUiShown = false
        NpcState.lastPromptKey = ''
    end
end

---@return table
local function icfg()
    return (Config.NPC and Config.NPC.interact) or {}
end

---@param npcId string
---@return vector3|nil
local function npcCoordsFor(id)
    local e = NpcState.registry[id]
    if e and DoesEntityExist(e.entity) then
        return GetEntityCoords(e.entity)
    end
    local npc = Config.NPC
    if not npc then
        return nil
    end
    local pt = npc.points and npc.points[id]
    if pt and pt.coords then
        local c = pt.coords
        return vector3(c.x, c.y, c.z)
    end
    if id == 'vega' and npc.coords then
        local c = npc.coords
        return vector3(c.x, c.y, c.z)
    end
    return nil
end

---@param npcId string
---@return boolean
local function npcEnabled(id)
    local pt = Config.NPC and Config.NPC.points and Config.NPC.points[id]
    if pt and pt.enabled == false then
        return false
    end
    local e = NpcState.registry[id]
    if e and e.enabled == false then
        return false
    end
    return true
end

---@param playerCoords vector3
---@param npcCoords vector3
---@param fwd vector3
---@param dotMin number
---@return number|nil
local function facingDot(playerCoords, npcCoords, fwd, dotMin)
    local toNx = npcCoords.x - playerCoords.x
    local toNy = npcCoords.y - playerCoords.y
    local len = math.sqrt(toNx * toNx + toNy * toNy)
    if len < 0.05 then
        return nil
    end
    local dot = (fwd.x * toNx + fwd.y * toNy) / len
    return dot
end

---@param world vector3
---@param text string
local function drawText3D(world, text)
    SetDrawOrigin(world.x, world.y, world.z, 0)
    SetTextScale(0.32, 0.32)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(230, 220, 255, 220)
    SetTextCentre(true)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

---@param ped integer
---@param npcCoords vector3
---@param rgba { r: integer, g: integer, b: integer, a: integer }
local function drawFootRing(ped, npcCoords, rgba)
    DrawMarker(
        1,
        npcCoords.x, npcCoords.y, npcCoords.z - 1.02,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.8, 0.8, 0.1,
        rgba.r, rgba.g, rgba.b, rgba.a,
        false, true, 2, false, nil, nil, false
    )
end

---@return table
local function defaultNpcTextUiStyle()
    return {
        backgroundColor = '#2e7d32',
        color = '#f1f8e9',
        fontSize = '1.35em',
        padding = '10px 18px',
        borderRadius = '8px',
    }
end

---@return { position: string, icon: string, style: table }
local function getNpcInteractTextUiOptions()
    local ic = icfg()
    local style = ic.textUiStyle
    if type(style) ~= 'table' then
        local loot = Config.Loot or {}
        style = loot.textUiStyle or defaultNpcTextUiStyle()
    end
    local pos = ic.textUiPosition
    if type(pos) ~= 'string' or pos == '' then
        pos = 'bottom-center'
    end
    local icon = ic.textUiIcon
    if type(icon) ~= 'string' or icon == '' then
        icon = 'comment-dots'
    end
    return {
        position = pos,
        icon = icon,
        style = style,
    }
end

---@param text string
---@param subText string|nil
---@param key string
local function showBottomPrompt(text, subText, key)
    local body = subText and (text .. '\n' .. subText) or text
    if NpcState.lastPromptKey ~= key then
        if NpcState.textUiShown then
            lib.hideTextUI()
        end
        local opts = getNpcInteractTextUiOptions()
        lib.showTextUI(body, {
            position = opts.position,
            icon = opts.icon,
            style = opts.style,
        })
        NpcState.textUiShown = true
        NpcState.lastPromptKey = key
    end
end

function MRD9.NPC.OnInteract(npcId)
    local ic = icfg()
    local ev = (type(ic.entryEvent) == 'string' and ic.entryEvent ~= '') and ic.entryEvent or 'mrd9:npc:interact'
    TriggerServerEvent(ev, npcId)
end

---@param x number
---@param y number
---@param refZ number
---@param sp table
---@return number
local function resolveSpawnZ(x, y, refZ, sp)
    local probeZ = tonumber(sp.groundProbeZ) or 120.0
    local footUp = tonumber(sp.footAboveGround) or 0.55
    local guard = tonumber(sp.minZGuardBelowConfig)
    if guard == nil then
        guard = -0.05
    end
    local okGround, gz = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, refZ + probeZ + 0.0, false)
    local candidate = (okGround and gz and gz > 1.0) and (gz + footUp) or (refZ + 0.05)
    return math.max(candidate, refZ + guard)
end

---@param ped integer
---@param x number
---@param y number
---@param refZ number
---@param heading number
---@param sp table
local function applyPedGroundZ(ped, x, y, refZ, heading, sp)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return
    end
    local z = resolveSpawnZ(x, y, refZ, sp)
    SetEntityCoordsNoOffset(ped, x + 0.0, y + 0.0, z, false, false, false)
    SetEntityHeading(ped, heading + 0.0)
end

---@return boolean
local function spawnVega()
    if vegaPed and vegaPed ~= 0 and DoesEntityExist(vegaPed) then
        return true
    end

    local modelName = Config.NPC and Config.NPC.model or 's_m_m_highsec_01'
    local model = GetHashKey(modelName)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print(('[jp-meridian9] Vega NPC: invalid model %s'):format(tostring(modelName)))
        MRD9.Log('Vega NPC: invalid model %s', tostring(modelName))
        return false
    end

    RequestModel(model)
    local deadline = GetGameTimer() + 15000
    while not HasModelLoaded(model) do
        if GetGameTimer() > deadline then
            print(('[jp-meridian9] Vega NPC: model load timeout %s'):format(tostring(modelName)))
            MRD9.Log('Vega NPC: model load timeout %s', tostring(modelName))
            return false
        end
        Wait(10)
    end

    local c = Config.NPC.coords
    local sp = (Config.NPC and Config.NPC.spawn) or {}
    local useNet = sp.networkPed ~= false

    RequestCollisionAtCoord(c.x + 0.0, c.y + 0.0, c.z + 0.0)
    local colWait = tonumber(sp.collisionWaitMs) or 450
    Wait(colWait)

    local spawnZ = resolveSpawnZ(c.x, c.y, c.z, sp)

    vegaPed = CreatePed(4, model, c.x + 0.0, c.y + 0.0, spawnZ, c.w + 0.0, useNet, true)
    if not vegaPed or vegaPed == 0 then
        SetModelAsNoLongerNeeded(model)
        print('[jp-meridian9] Vega NPC: CreatePed returned 0 (network/streaming/collision)')
        MRD9.Log('Vega NPC: CreatePed failed')
        return false
    end

    SetEntityAsMissionEntity(vegaPed, true, true)
    SetEntityInvincible(vegaPed, Config.NPC.invincible == true)
    SetBlockingOfNonTemporaryEvents(vegaPed, Config.NPC.blockEvents ~= false)

    applyPedGroundZ(vegaPed, c.x, c.y, c.z, c.w, sp)
    SetEntityVisible(vegaPed, true, false)

    local scenario = Config.NPC.scenario
    if type(scenario) == 'string' and scenario ~= '' then
        TaskStartScenarioInPlace(vegaPed, scenario, 0, true)
    end

    local settle = tonumber(sp.postScenarioSettleMs)
    if settle and settle > 0 then
        Wait(settle)
        local p = GetEntityCoords(vegaPed)
        applyPedGroundZ(vegaPed, p.x, p.y, c.z, c.w, sp)
    end

    FreezeEntityPosition(vegaPed, Config.NPC.freeze == true)

    SetModelAsNoLongerNeeded(model)

    local blipCfg = Config.NPC.blip
    local labelText = 'Vega'
    if blipCfg then
        local labelKey = blipCfg.labelKey
        labelText = (labelKey and type(labelKey) == 'string' and _(labelKey)) or blipCfg.label or labelText
    end

    NpcState.registry['vega'] = {
        id = 'vega',
        entity = vegaPed,
        coords = vector3(c.x, c.y, c.z),
        heading = c.w,
        label = labelText,
        enabled = true,
    }

    if blipCfg and blipCfg.enabled then
        vegaBlip = AddBlipForCoord(c.x, c.y, c.z)
        SetBlipSprite(vegaBlip, blipCfg.sprite or 280)
        SetBlipColour(vegaBlip, blipCfg.color or 4)
        SetBlipScale(vegaBlip, blipCfg.scale or 0.8)
        SetBlipAsShortRange(vegaBlip, blipCfg.shortRange ~= false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(labelText)
        EndTextCommandSetBlipName(vegaBlip)
    end

    local pFinal = GetEntityCoords(vegaPed)
    MRD9.Log('Vega NPC spawned at %.2f, %.2f, %.2f', pFinal.x, pFinal.y, pFinal.z)
    return true
end

local function despawnVega()
    hidePrompt()
    NpcState.registry['vega'] = nil
    if vegaPed and DoesEntityExist(vegaPed) then
        DeleteEntity(vegaPed)
        vegaPed = nil
    end
    vegaBlip = removeBlipSafe(vegaBlip)
end

---@param ids string[]
---@return string
local function sigIds(ids)
    return table.concat(ids, ',')
end

CreateThread(function()
    local sp = (Config.NPC and Config.NPC.spawn) or {}
    local firstWait = tonumber(sp.waitBeforeMs) or 2000
    local maxA = math.max(1, tonumber(sp.maxAttempts) or 8)
    local retryMs = tonumber(sp.retryMs) or 5000

    Wait(firstWait)
    for attempt = 1, maxA do
        if spawnVega() then
            return
        end
        if attempt < maxA then
            print(('[jp-meridian9] Vega NPC: spawn retry %d/%d (wait %dms)'):format(attempt + 1, maxA, retryMs))
            Wait(retryMs)
        end
    end
    print('[jp-meridian9] CRITICAL: Vega NPC spawn failed after all attempts. Check F8, model, collision, OneSync.')
end)

CreateThread(function()
    while true do
        local ic = icfg()
        local promptDist = tonumber(ic.promptDistance) or 3.0
        local near = {}
        local ped = PlayerPedId()
        if ped ~= 0 and not IsPedInAnyVehicle(ped, false) then
            local pcoords = GetEntityCoords(ped)
            for id, entry in pairs(NpcState.registry) do
                if npcEnabled(id) and entry and DoesEntityExist(entry.entity) then
                    local nc = GetEntityCoords(entry.entity)
                    if #(pcoords - nc) <= promptDist then
                        near[#near + 1] = id
                    end
                end
            end
        end
        table.sort(near)
        local sig = sigIds(near)
        if sig ~= NpcState.lastNearSig then
            NpcState.lastNearSig = sig
        end
        NpcState.nearIds = near

        if #near == 0 then
            Wait(500)
        else
            Wait(200)
        end
    end
end)

CreateThread(function()
    while true do
        local near = NpcState.nearIds
        if #near == 0 then
            hidePrompt()
            Wait(500)
        else
            local ic = icfg()
            local ped = PlayerPedId()
            if ped == 0 or IsPedInAnyVehicle(ped, false) then
                hidePrompt()
                Wait(200)
            else
                local pcoords = GetEntityCoords(ped)
                local fwd = GetEntityForwardVector(ped)
                local promptDist = tonumber(ic.promptDistance) or 3.0
                local triggerDist = tonumber(ic.triggerDistance) or 2.0
                local dotMin = tonumber(ic.facingDotMin) or 0.5
                local hud = ic.hud or {}
                local style = hud.style or 'bottom_center'
                local rgba = hud.outlineColor or { r = 140, g = 60, b = 220, a = 180 }

                local bestId = nil
                local bestDist = 1e9
                local bestCoords = nil

                for _, id in ipairs(near) do
                    local nc = npcCoordsFor(id)
                    if nc then
                        local d = #(pcoords - nc)
                        if d < bestDist then
                            bestDist = d
                            bestId = id
                            bestCoords = nc
                        end
                    end
                end

                if not bestId or not bestCoords then
                    hidePrompt()
                    Wait(0)
                else
                    local dot = facingDot(pcoords, bestCoords, fwd, dotMin)
                    local facingOk = dot ~= nil and dot >= dotMin
                    local now = GetGameTimer()
                    local onCd = now < NpcState.clientCooldownUntil
                    local baseTalk = _('npc_prompt_talk')
                    local cfgText = hud.text
                    if type(cfgText) == 'string' and cfgText ~= '' then
                        baseTalk = cfgText
                    end
                    local busyText = _('npc_prompt_busy')

                    if not facingOk or bestDist > promptDist then
                        hidePrompt()
                    else
                        local sub = hud.subText
                        if type(sub) ~= 'string' or sub == '' then
                            sub = nil
                        end
                        if hud.showOutline ~= false then
                            drawFootRing(ped, bestCoords, rgba)
                        end

                        local promptLine = onCd and busyText or baseTalk
                        local promptKey = promptLine .. '|' .. tostring(sub or '')

                        if style == 'bottom_center' or style == 'both' then
                            showBottomPrompt(promptLine, sub, promptKey)
                        else
                            hidePrompt()
                        end

                        if style == 'above_head' or style == 'both' then
                            local line = sub and (promptLine .. '  ' .. sub) or promptLine
                            drawText3D(vector3(bestCoords.x, bestCoords.y, bestCoords.z + 1.05), line)
                        end

                        local key = tonumber(ic.key) or 38
                        if
                            not onCd
                            and facingOk
                            and bestDist <= triggerDist
                            and IsControlJustReleased(0, key)
                        then
                            local cdMs = tonumber(ic.cooldownMs) or 800
                            NpcState.clientCooldownUntil = now + cdMs
                            lib.hideTextUI()
                            NpcState.textUiShown = false
                            NpcState.lastPromptKey = ''
                            local busyOpts = getNpcInteractTextUiOptions()
                            lib.showTextUI(busyText, {
                                position = busyOpts.position,
                                icon = busyOpts.icon,
                                style = busyOpts.style,
                            })
                            NpcState.textUiShown = true
                            NpcState.lastPromptKey = 'busy_force'
                            MRD9.NPC.OnInteract(bestId)
                            SetTimeout(cdMs, function()
                                if NpcState.lastPromptKey == 'busy_force' then
                                    lib.hideTextUI()
                                    NpcState.textUiShown = false
                                    NpcState.lastPromptKey = ''
                                end
                            end)
                        end
                    end
                    Wait(0)
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end
    hidePrompt()
    despawnVega()
end)
